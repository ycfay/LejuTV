import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lejutv/core/remote_http_server.dart';
import 'package:lejutv/model/channel.dart';
import 'package:lejutv/stores/channel.storage.dart';
import 'package:lejutv/widgets/channel_manager_dialog.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lejutv/components/webview/webview_component.dart';

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
  bool _webViewReady = false;
  static const String _videoResizeScriptAsset =
      'assets/js/default_video_resize.js';
  String? _videoResizeScript;
  List<Channel> channels = [];
  int currentChannelIndex = 0;
  String? _loadedChannelUrl;
  final FocusNode focusNode = FocusNode();
  final FocusNode sidebarFocusNode = FocusNode();
  final RemoteHttpServer remoteServer = RemoteHttpServer();

  Timer? hintTimer;
  Timer? wheelTimer;
  Timer? statusTimer;
  Timer? sidebarTimer;
  // Do not persist this transient drawer's offset in PageStorage. Restoring a
  // stale offset is what causes the list to jump back to the top after it has
  // been positioned on the current channel.
  final ScrollController sidebarScrollController = ScrollController(
    keepScrollOffset: false,
  );
  final Map<int, GlobalKey> sidebarItemKeys = <int, GlobalKey>{};

  String status = '正在加载电视...';
  String lastAction = '就绪';

  bool hintVisible = true;
  bool wheelVisible = false;
  bool _channelManagerOpen = false;
  bool sidebarVisible = false;
  bool sidebarPositioned = false;
  int sidebarSelectedIndex = 0;
  DateTime? _lastSidebarOpen;

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
    if (_webViewReady && channels.isNotEmpty) {
      await loadChannel(currentChannelIndex);
    }
  }

  Future<void> loadChannel(int index) async {
    if (channels.isEmpty) return;
    final nextIndex = (index + channels.length) % channels.length;
    final nextChannel = channels[nextIndex];
    if (_loadedChannelUrl == nextChannel.url) {
      currentChannelIndex = nextIndex;
      return;
    }
    currentChannelIndex = nextIndex;
    await ChannelStorage.instance.saveSelectedChannelIndex(currentChannelIndex);
    final channel = channels[currentChannelIndex];
    if (mounted) {
      setState(() => status = '正在加载：${channel.name}');
    }
    await controller.loadRequest(Uri.parse(channel.url));
    _loadedChannelUrl = channel.url;
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
    _channelManagerOpen = true;
    try {
      final address = await remoteServer.start();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        requestFocus: true,
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
      _channelManagerOpen = false;
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

  void openSidebar() {
    if (channels.isEmpty) return;
    final now = DateTime.now();
    if (_lastSidebarOpen != null &&
        now.difference(_lastSidebarOpen!) < const Duration(milliseconds: 350)) {
      return;
    }
    _lastSidebarOpen = now;
    // 遥控器确认键可能同时产生 KeyDown/KeyRepeat；避免重复打开重建
    // ListView，导致滚动位置被重置到顶部。
    if (sidebarVisible) {
      refreshSidebarTimer();
      return;
    }
    setState(() {
      sidebarVisible = true;
      sidebarPositioned = false;
      sidebarSelectedIndex = currentChannelIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && sidebarVisible) sidebarFocusNode.requestFocus();
      ensureSidebarSelectionVisible();
    });
    // 抽屉和 ListView 同时首次布局时，ListView 可能先恢复到 offset=0；
    // 在布局稳定后再校正一次，确保当前频道始终可见。
    for (final delay in const [80, 240, 500]) {
      Future<void>.delayed(Duration(milliseconds: delay), () {
        if (mounted && sidebarVisible && !sidebarPositioned &&
            sidebarScrollController.hasClients &&
            sidebarScrollController.position.maxScrollExtent > 0) {
          ensureSidebarSelectionVisible();
          final target = (sidebarSelectedIndex * 72.0 -
                  sidebarScrollController.position.viewportDimension / 2 +
                  36.0)
              .clamp(0.0, sidebarScrollController.position.maxScrollExtent)
              .toDouble();
          if ((sidebarScrollController.offset - target).abs() < 2) {
            setState(() => sidebarPositioned = true);
          }
        }
      });
    }
    refreshSidebarTimer();
  }

  void refreshSidebarTimer() {
    sidebarTimer?.cancel();
    sidebarTimer = Timer(const Duration(seconds: 5), closeSidebar);
  }

  void closeSidebar() {
    sidebarTimer?.cancel();
    if (mounted && sidebarVisible) {
      setState(() => sidebarVisible = false);
      focusNode.requestFocus();
    }
  }

  void moveSidebarSelection(int delta) {
    final count = channels.length + 1;
    setState(() {
      sidebarSelectedIndex = (sidebarSelectedIndex + delta + count) % count;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ensureSidebarSelectionVisible();
    });
    refreshSidebarTimer();
  }

  void ensureSidebarSelectionVisible() {
    debugPrint(
      'scroll offset=${sidebarScrollController.hasClients ? sidebarScrollController.offset : -1} '
      'max=${sidebarScrollController.hasClients ? sidebarScrollController.position.maxScrollExtent : -1} '
      'selected=$sidebarSelectedIndex',
    );
    if (!sidebarScrollController.hasClients) return;
    // During the first frame the viewport may report maxScrollExtent=0 even
    // though the list has not finished laying out. Never overwrite a valid
    // offset with zero during that transient state.
    if (sidebarSelectedIndex > 0 &&
        sidebarScrollController.position.maxScrollExtent <= 0) {
      return;
    }
    const itemExtent = 72.0;
    final viewport = sidebarScrollController.position.viewportDimension;
    final target =
        (sidebarSelectedIndex * itemExtent - viewport / 2 + itemExtent / 2)
            .clamp(0.0, sidebarScrollController.position.maxScrollExtent)
            .toDouble();
    if ((sidebarScrollController.offset - target).abs() > 1) {
      sidebarScrollController.jumpTo(target);
    }
  }

  Future<void> confirmSidebarSelection() async {
    refreshSidebarTimer();
    if (sidebarSelectedIndex < channels.length) {
      final index = sidebarSelectedIndex;
      closeSidebar();
      await loadChannel(index);
    } else {
      closeSidebar();
      await openChannelManager();
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

    if (sidebarVisible) {
      if (key == LogicalKeyboardKey.arrowUp) {
        moveSidebarSelection(-1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        moveSidebarSelection(1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.space) {
        unawaited(confirmSidebarSelection());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.goBack ||
          key == LogicalKeyboardKey.backspace) {
        closeSidebar();
        return KeyEventResult.handled;
      }
      refreshSidebarTimer();
      return KeyEventResult.handled;
    }

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
      openSidebar();
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
    statusTimer?.cancel();
    sidebarTimer?.cancel();
    sidebarScrollController.dispose();
    focusNode.dispose();
    sidebarFocusNode.dispose();
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
            WebViewComponent(
              onControllerReady: (value) {
                controller = value;
                _webViewReady = true;
                if (channels.isNotEmpty) {
                  unawaited(loadChannel(currentChannelIndex));
                }
              },
              onPageStarted: (_) {
                statusTimer?.cancel();
                if (mounted) setState(() => status = '正在加载...');
                unawaited(injectVideoResizeScript());
              },
              onPageFinished: (_) {
                unawaited(injectVideoResizeScript());
                if (mounted) {
                  setState(() => status = '加载完成');
                  statusTimer?.cancel();
                  statusTimer = Timer(const Duration(seconds: 3), () {
                    if (mounted) setState(() => status = '');
                  });
                  if (!_channelManagerOpen) focusNode.requestFocus();
                }
              },
              onWebResourceError: (error) {
                statusTimer?.cancel();
                if (mounted) {
                  setState(() => status = '加载失败：${error.description}');
                }
              },
            ),

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

            if (sidebarVisible)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !sidebarPositioned,
                  child: Opacity(
                    opacity: sidebarPositioned ? 1 : 0,
                    child: buildSidebar(),
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

  Widget buildSidebar() {
    debugPrint(
      'openSidebar visible=$sidebarVisible '
      'current=$currentChannelIndex selected=$sidebarSelectedIndex',
    );
    final width = (MediaQuery.sizeOf(context).width * 0.36)
        .clamp(260.0, 420.0)
        .toDouble();
    return Align(
      alignment: Alignment.centerRight,
      child: Focus(
        focusNode: sidebarFocusNode,
        onKeyEvent: (node, event) {
          // 主页面 Focus 负责业务处理；侧边栏挂载后由它独占遥控器按键，
          // 避免确认键再次冒泡到 WebView/主页面造成菜单状态冲突。
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            final key = event.logicalKey;
            if (event is KeyRepeatEvent &&
                (key == LogicalKeyboardKey.enter ||
                    key == LogicalKeyboardKey.select ||
                    key == LogicalKeyboardKey.numpadEnter ||
                    key == LogicalKeyboardKey.space)) {
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.arrowUp) {
              moveSidebarSelection(-1);
            } else if (key == LogicalKeyboardKey.arrowDown) {
              moveSidebarSelection(1);
            } else if (key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.select ||
                key == LogicalKeyboardKey.numpadEnter ||
                key == LogicalKeyboardKey.space) {
              unawaited(confirmSidebarSelection());
            } else if (key == LogicalKeyboardKey.arrowLeft ||
                key == LogicalKeyboardKey.escape ||
                key == LogicalKeyboardKey.goBack ||
                key == LogicalKeyboardKey.backspace) {
              closeSidebar();
            } else {
              refreshSidebarTimer();
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Material(
          color: const Color(0xF20B101A),
          child: SizedBox(
            width: width,
            height: double.infinity,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Text(
                      '频道列表',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: sidebarScrollController,
                      primary: false,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemExtent: 72,
                      itemCount: channels.length + 1,
                      itemBuilder: (context, index) {
                        final isSettings = index == channels.length;
                        final selected = index == sidebarSelectedIndex;
                        final title = isSettings
                            ? '频道管理'
                            : channels[index].name;
                        final itemKey = sidebarItemKeys.putIfAbsent(
                          index,
                          GlobalKey.new,
                        );
                        return AnimatedContainer(
                          key: itemKey,
                          duration: const Duration(milliseconds: 120),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF1685E5)
                                : const Color(0x26FFFFFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? Colors.white70 : Colors.white12,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                if (sidebarSelectedIndex != index) {
                                  setState(() => sidebarSelectedIndex = index);
                                }
                                unawaited(confirmSidebarSelection());
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (!isSettings)
                                      Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Text(
                      '↑↓ 选择    OK 确认    ← 返回',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
