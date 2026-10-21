import 'dart:ui';

class ShaderManager {
  static FragmentProgram? _background;
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
}
