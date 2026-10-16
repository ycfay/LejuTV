import 'package:flutter/material.dart';
import 'package:lejutv/global.dart';
import 'package:lejutv/page/splash_page.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:get/get.dart';

final easyLoad = EasyLoading.init();
final botToast = BotToastInit();

void main() => Global.init().then(
  (e) => runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        child = easyLoad(context, child);
        child = botToast(context, child);
        return child;
      },
      home: SplashPage(),
    ),
  ),
);
