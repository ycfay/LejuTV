import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lejutv/model/channel.dart';
import 'package:lejutv/stores/channel.storage.dart';
import 'package:lejutv/remote_http_server.dart';
import 'package:lejutv/widgets/channel_manager_dialog.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TvPage extends StatefulWidget {
  const TvPage({super.key});

  @override
  State<TvPage> createState() => _TvPageState();
}
//https://www.sztv.com.cn/dianshi.shtml?id=7868
//https://www.douyin.com/?recommend=1&from_nav=1

class _TvPageState extends State<TvPage> {
  //static const String homeUrl = 'https://www.sztv.com.cn/dianshi.shtml?id=7868';
  //static const String homeUrl = 'https://www.douyin.com/?recommend=1&from_nav=1';
  //static const String homeUrl = 'https://test.ustc.edu.cn/';
  late final WebViewController controller;
  static const String _videoResizeScriptAsset =
      'assets/js/default_video_resize.js';
  String? _videoResizeScript;
  List<Channel> channels = [];
  int currentChannelIndex = 0;
  final FocusNode focusNode = FocusNode();
  final RemoteHttpServer remoteServer = RemoteHttpServer();

  Timer? hintTimer;
  Timer? wheelTimer;

  String status = '正在加载电视...';
  String lastAction = '就绪';

  bool hintVisible = true;
  bool wheelVisible = false;

  int selectedIndex = 0;
  DateTime? lastBackPress;

  static const actions = [
    ('无', '无', ''),
    ('频道管理', '无', 'b'),
    ('收藏', '收藏 / 取消收藏', 'c'),
    ('全屏', '网页内全屏', 'y'),
  ];

  @override
  void initState() {
    super.initState();

    controller = WebViewController();
    unawaited(initializeWebView());

    showHint('准备就绪', initial: true);
  }

  Future<void> initializeWebView() async {
    // Load the same bundled resize script once, then inject it at navigation
    // start and retry after the document has finished loading.
    _videoResizeScript = await rootBundle.loadString(_videoResizeScriptAsset);
    channels = await ChannelStorage.instance.getChannels();
    if (channels.isEmpty) {
      throw const FormatException('频道列表为空');
    }
    final savedIndex = ChannelStorage.instance.getSelectedChannelIndex();
    currentChannelIndex =
        savedIndex != null && savedIndex >= 0 && savedIndex < channels.length
        ? savedIndex
        : 0;
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(Colors.black);
    await controller.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/116.0.0.0 Safari/537.36',
    );

    final platformController = controller.platform;
    if (platformController is AndroidWebViewController) {
      await platformController.setUseWideViewPort(true);

      await platformController.enableZoom(false);
      await platformController.setMediaPlaybackRequiresUserGesture(false);
    }

    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) {
            setState(() => status = '正在加载...');
          }
          unawaited(injectVideoResizeScript());
        },
        onPageFinished: (url) {
          unawaited(injectVideoResizeScript());
          if (mounted) {
            setState(() => status = '加载完成');
            focusNode.requestFocus();
          }
        },
        onWebResourceError: (error) {
          debugPrint('失败 URL: ${error.url}');
          debugPrint('错误码: ${error.errorCode}');
          debugPrint('错误描述: ${error.description}');
          debugPrint('主页面错误: ${error.isForMainFrame}');

          if (mounted) {
            setState(() => status = '加载失败：${error.description}');
          }
        },
      ),
    );
    await loadChannel(currentChannelIndex);
  }

  Future<void> loadChannel(int index) async {
    if (channels.isEmpty) return;
    currentChannelIndex = (index + channels.length) % channels.length;
    await ChannelStorage.instance.saveSelectedChannelIndex(currentChannelIndex);
    final channel = channels[currentChannelIndex];
    if (mounted) {
      setState(() => status = '正在加载：${channel.name}');
    }
    await controller.loadRequest(Uri.parse(channel.url));
    showHint('正在播放：${channel.name}');
  }

  Future<void> switchChannel(int delta) async {
    if (channels.isEmpty) return;
    await loadChannel(currentChannelIndex + delta);
  }

  Future<void> injectVideoResizeScript() async {
    final script = _videoResizeScript;
    if (script == null) return;

    try {
      await controller.runJavaScript(script);
    } catch (error) {
      // Navigation may replace the document while the start callback is
      // firing; onPageFinished retries for the resulting document.
      debugPrint('注入视频适配脚本失败：$error');
    }
  }

  void showHint(String text, {bool initial = false}) {
    hintTimer?.cancel();
    setState(() {
      lastAction = text;
      hintVisible = true;
    });

    hintTimer = Timer(Duration(milliseconds: initial ? 3600 : 1200), () {
      if (mounted) {
        setState(() => hintVisible = false);
      }
    });
  }

  Future<void> sendKey(String key, String code, int keyCode) async {
    final targetExpression = key == ' '
        ? 'document.activeElement || document.body || document'
        : 'document';
    final js =
        """
      (function() {
        var target = $targetExpression;

        ['keydown', 'keyup'].forEach(function(type) {
          var event = new KeyboardEvent(type, {
            key: '$key',
            code: '$code',
            keyCode: $keyCode,
            which: $keyCode,
            bubbles: true,
            cancelable: true
          });

          try {
            Object.defineProperty(event, 'keyCode', {
              get: function() { return $keyCode; }
            });
            Object.defineProperty(event, 'which', {
              get: function() { return $keyCode; }
            });
          } catch (e) {}

          target.dispatchEvent(event);
        });
      })();
    """;

    try {
      await controller.runJavaScript(js);
    } catch (e) {
      debugPrint('发送按键失败：$e');
    }
  }

  Future<void> executeAction(int index) async {
    final action = actions[index];
    final shortcut = action.$3;

    if (shortcut == 'b') {
      await openChannelManager();
      return;
    }

    if (shortcut.isNotEmpty) {
      const codes = {'c': 67, 'y': 89};

      await sendKey(shortcut, 'Key${shortcut.toUpperCase()}', codes[shortcut]!);
    }

    showHint(action.$2);
  }

  Future<void> openChannelManager() async {
    try {
      final address = await remoteServer.start();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => ChannelManagerDialog(
          address: address,
          channels: channels,
          onChanged: reloadChannels,
        ),
      );
      await reloadChannels();
    } catch (error) {
      if (mounted) showHint('频道管理启动失败：$error');
    } finally {
      await remoteServer.stop();
    }
    if (mounted) focusNode.requestFocus();
  }

  Future<void> reloadChannels() async {
    final currentUrl =
        channels.isNotEmpty && currentChannelIndex < channels.length
        ? channels[currentChannelIndex].url
        : null;
    final next = await ChannelStorage.instance.getChannels();
    if (!mounted) return;
    setState(() {
      channels = next;
      currentChannelIndex = currentUrl == null
          ? 0
          : next
                .indexWhere((channel) => channel.url == currentUrl)
                .clamp(0, math.max(0, next.length - 1));
    });
    if (channels.isNotEmpty) await loadChannel(currentChannelIndex);
  }

  void showWheel(int direction) {
    if (!wheelVisible) {
      setState(() {
        wheelVisible = true;
        selectedIndex = 0;
      });
    } else {
      moveSelection(direction);
    }

    refreshWheelTimer();
  }

  void moveSelection(int delta) {
    setState(() {
      selectedIndex = (selectedIndex + delta + actions.length) % actions.length;
    });

    refreshWheelTimer();
  }

  void refreshWheelTimer() {
    wheelTimer?.cancel();

    wheelTimer = Timer(
      const Duration(milliseconds: 1500),
      () => hideWheel(executeSelected: true),
    );
  }

  void hideWheel({bool executeSelected = false}) {
    wheelTimer?.cancel();

    if (!wheelVisible) return;

    final index = selectedIndex;

    setState(() {
      wheelVisible = false;
      selectedIndex = 0;
    });

    if (executeSelected && index != 0) {
      executeAction(index);
    }
  }

  Future<void> handleBack() async {
    final now = DateTime.now();

    if (lastBackPress != null &&
        now.difference(lastBackPress!) < const Duration(seconds: 2)) {
      await SystemNavigator.pop();
      return;
    }

    lastBackPress = now;
    showHint('返回 / 退出');

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('再按一次返回退出')));
    }
  }

  KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (wheelVisible) {
      if (key == LogicalKeyboardKey.arrowLeft) {
        moveSelection(-1);
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.arrowRight) {
        moveSelection(1);
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.numpadEnter) {
        hideWheel(executeSelected: true);
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.goBack ||
          key == LogicalKeyboardKey.backspace ||
          key == LogicalKeyboardKey.mediaTopMenu) {
        hideWheel();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown) {
        final up = key == LogicalKeyboardKey.arrowUp;

        sendKey(
          up ? 'ArrowUp' : 'ArrowDown',
          up ? 'ArrowUp' : 'ArrowDown',
          up ? 38 : 40,
        );

        showHint(up ? '上一个视频' : '下一个视频');
        hideWheel();
        return KeyEventResult.handled;
      }

      refreshWheelTimer();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      final delta = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      switchChannel(delta);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      sendKey(' ', 'Space', 32);
      showHint('暂停 / 播放');
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      showWheel(key == LogicalKeyboardKey.arrowLeft ? -1 : 1);
      showHint('打开功能轮盘');
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.mediaTopMenu ||
        key == LogicalKeyboardKey.keyM) {
      showHint('显示遥控指南');
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.backspace) {
      handleBack();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    hintTimer?.cancel();
    wheelTimer?.cancel();
    focusNode.dispose();
    unawaited(remoteServer.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        focusNode: focusNode,
        onKeyEvent: onKeyEvent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(controller: controller),

            Positioned(
              left: 12,
              top: 8,
              child: IgnorePointer(
                child: Text(
                  status,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ),

            if (hintVisible)
              Positioned(
                right: 22,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x70080C14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          hint('上键  上一个视频'),
                          hint('下键  下一个视频'),
                          hint('OK    播放 / 暂停'),
                          hint('左右  功能轮盘'),
                          const SizedBox(height: 5),
                          Text(
                            lastAction,
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (wheelVisible) Center(child: buildWheel()),
          ],
        ),
      ),
    );
  }

  Widget hint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  Widget buildWheel() {
    final size = (MediaQuery.sizeOf(context).shortestSide * 0.72)
        .clamp(260.0, 340.0)
        .toDouble();

    final radius = size * 0.38;
    final itemWidth = size * 0.23;
    final itemHeight = size * 0.12;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x76060A12),
        border: Border.all(color: Colors.white24),
      ),
      child: Stack(
        children: [
          for (int i = 0; i < actions.length; i++)
            buildWheelItem(i, size, radius, itemWidth, itemHeight),

          Center(
            child: SizedBox(
              width: size * 0.34,
              child: Text(
                actions[selectedIndex].$2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWheelItem(
    int index,
    double size,
    double radius,
    double width,
    double height,
  ) {
    final angle = -math.pi / 2 + 2 * math.pi * index / actions.length;

    final center = size / 2;
    final x = center + math.cos(angle) * radius - width / 2;
    final y = center + math.sin(angle) * radius - height / 2;

    final selected = index == selectedIndex;

    return Positioned(
      left: x,
      top: y,
      width: width,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: selected ? const Color(0xE00079FB) : const Color(0x36FFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xA0A0D2FF) : const Color(0x22FFFFFF),
          ),
        ),
        child: Text(
          actions[index].$1,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: selected ? 11.5 : 10.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
