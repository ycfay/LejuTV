import 'dart:ui';

class ShaderManager {
  static FragmentProgram? _background;
  static FragmentProgram? _flowProgram;
  static FragmentProgram? _highLine;
  static FragmentProgram? _itemBackground;

  static Future<void> load() async {
    _background ??= await FragmentProgram.fromAsset(
      'assets/shaders/background.frag',
    );
  }

  static FragmentShader background() {
    final program = _background;
    if (program == null) {
      throw StateError('ShaderManager.load() must be awaited first.');
    }
    return program.fragmentShader();
  }

  static FragmentShader flow() {
    return _flowProgram!.fragmentShader();
  }

  static FragmentShader highLine() {
    return _highLine!.fragmentShader();
  }

  static FragmentShader itemBackground() {
    return _itemBackground!.fragmentShader();
  }
}
