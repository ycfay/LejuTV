import 'dart:ui';

class ShaderManager {
  static FragmentProgram? _flowProgram;
  static FragmentProgram? _highLine;
  static FragmentProgram? _itemBackground;

  static Future<void> load() async {
    // _flowProgram = await FragmentProgram.fromAsset(
    //   'assets/shaders/flow_light.frag',
    // );
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
