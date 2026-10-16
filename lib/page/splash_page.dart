import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lejutv/graphics/shader_manager.dart';
import 'package:lejutv/page/start_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final AudioPlayer _openingPlayer;
  Future<void>? _shaderLoad;
  bool _isOpening = false;
  bool _audioReleased = false;

  @override
  void initState() {
    super.initState();
    _openingPlayer = AudioPlayer();
    unawaited(_playOpeningMusic());
    _shaderLoad = ShaderManager.load();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  void _openHome() {
    if (!mounted || _isOpening) return;
    _isOpening = true;
    _controller.stop();
    unawaited(_releaseOpeningMusic());
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const StartPage(),
        transitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(_releaseOpeningMusic());
    super.dispose();
  }

  Future<void> _playOpeningMusic() async {
    try {
      debugPrint('[开场音乐] 开始初始化播放器');

      await _openingPlayer.setReleaseMode(ReleaseMode.stop);
      await _openingPlayer.setVolume(1.0);

      debugPrint('[开场音乐] 开始播放 opening.mp3');

      await _openingPlayer.play(AssetSource('audio/opening.mp3'));

      debugPrint('[开场音乐] 播放命令已执行');
    } catch (e, stackTrace) {
      debugPrint('[开场音乐] 播放失败: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _releaseOpeningMusic() async {
    if (_audioReleased) return;
    _audioReleased = true;
    try {
      await _openingPlayer.stop();
    } finally {
      await _openingPlayer.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020307),
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            _openHome();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: FutureBuilder<void>(
          future: _shaderLoad,
          builder: (context, snapshot) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Stack(
                fit: StackFit.expand,
                children: [
                  if (snapshot.connectionState == ConnectionState.done &&
                      !snapshot.hasError)
                    CustomPaint(
                      painter: _BackgroundPainter(
                        shader: ShaderManager.background(),
                        progress: _controller.value,
                      ),
                    )
                  else
                    const _FallbackSplash(),
                  Center(child: _Logo(progress: _controller.value)),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 100,
                    child: Text(
                      '按下控制器上的确认键继续',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xBFFFFFFF),
                        fontSize: 14,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter({required this.shader, required this.progress});

  final ui.FragmentShader shader;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, progress * 30.0);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.shader != shader;
}

class _Logo extends StatelessWidget {
  const _Logo({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final pulse = (math.sin(progress * math.pi * 20) + 1) / 2;
    return SizedBox(
      width: 240,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 88 + pulse * 38,
            height: 88 + pulse * 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5 - pulse * 0.28),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x99E9D8B2)
                      .withValues(alpha: 0.2 + pulse * 0.22),
                  blurRadius: 20 + pulse * 28,
                  spreadRadius: 2 + pulse * 8,
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFF7F5F0),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x99FFFFFF), blurRadius: 18)],
            ),
            child: ClipOval(
              child: Transform.scale(
                scale: 1.3, // 放大图片，修改这里
                child: Image.asset('assets/imgaes/logo.png', fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackSplash extends StatelessWidget {
  const _FallbackSplash();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFF020307));
  }
}
