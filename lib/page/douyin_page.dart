import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lejutv/components/webview/webview_component.dart';

class DouyinPage extends StatefulWidget {
  const DouyinPage({super.key});

  @override
  State<DouyinPage> createState() => _DouyinPageState();
}
//https://www.sztv.com.cn/dianshi.shtml?id=7868
//https://www.douyin.com/?recommend=1&from_nav=1

class _DouyinPageState extends State<DouyinPage> {
  //static const String homeUrl = 'https://www.sztv.com.cn/dianshi.shtml?id=7868';
  static const String homeUrl =
      "https://www.douyin.com/?recommend=1&from_nav=1";

  //static const String homeUrl = 'https://test.ustc.edu.cn/';
  // Use the official HTTPS entry point instead of the old test endpoint.
  //static const String homeUrl = 'https://www.yangshipin.cn/tv/home?pid=600001859';

  late final WebViewController controller;
  final FocusNode focusNode = FocusNode();

  Timer? hintTimer;
  Timer? wheelTimer;
  Timer? statusTimer;

  String status = '正在加载抖音...';
  String lastAction = '就绪';

  bool hintVisible = true;
  bool wheelVisible = false;

  int selectedIndex = 0;
  DateTime? lastBackPress;

  static const actions = [
    ('无', '无', ''),
    ('点赞', '赞 / 取消赞', 'z'),
    ('收藏', '收藏 / 取消收藏', 'c'),
    ('关注', '关注 / 取消关注', 'g'),
    ('评论', '评论', 'x'),
    ('弹幕', '弹幕开关', 'b'),
    ('清屏', '清屏', 'j'),
    ('全屏', '网页内全屏', 'y'),
  ];

  @override
  void initState() {
    super.initState();

    showHint('准备就绪', initial: true);
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

    if (shortcut.isNotEmpty) {
      const codes = {
        'z': 90,
        'c': 67,
        'g': 71,
        'x': 88,
        'b': 66,
        'j': 74,
        'y': 89,
      };

      await sendKey(shortcut, 'Key${shortcut.toUpperCase()}', codes[shortcut]!);
    }

    showHint(action.$2);
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
      final up = key == LogicalKeyboardKey.arrowUp;

      sendKey(
        up ? 'ArrowUp' : 'ArrowDown',
        up ? 'ArrowUp' : 'ArrowDown',
        up ? 38 : 40,
      );

      showHint(up ? '上一个视频' : '下一个视频');
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
    statusTimer?.cancel();
    focusNode.dispose();
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
              initialUrl: homeUrl,
              onControllerReady: (value) => controller = value,
              onPageStarted: (_) {
                statusTimer?.cancel();
                if (mounted) setState(() => status = '正在加载...');
              },
              onPageFinished: (_) {
                if (mounted) {
                  setState(() => status = '加载完成');
                  statusTimer?.cancel();
                  statusTimer = Timer(const Duration(seconds: 3), () {
                    if (mounted) setState(() => status = '');
                  });
                  focusNode.requestFocus();
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
