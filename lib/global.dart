import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lejutv/graphics/shader_manager.dart';
import 'package:lejutv/stores/base.storage.dart';

/// 全局配置
class Global {
  /// 是否第一次打开
  static bool isFirstOpen = false;

  /// 是否 release
  static bool get isRelease => const bool.fromEnvironment("dart.vm.product");

  /// init
  static Future init() async {
    /// 运行初始
    WidgetsFlutterBinding.ensureInitialized();

    ///Shader
    await ShaderManager.load();

    /// 本地存储初始化
    await BaseStorage.instance.init();

    ///竖屏
    //await Flame.device.setPortrait();
    // 强制竖屏
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);
    /// 强制横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 读取离线用户信息
    // var profileJSON = LoacalStorage().getJSON(STORAGE_USER_PROFILE_KEY);
    // if (profileJSON != null) {
    //   profile = UserLoginResponseModel.fromJson(profileJSON);
    //   isOfflineLogin = true;
    // }

    /// android 状态栏为透明的沉浸
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      );
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
  }
}
