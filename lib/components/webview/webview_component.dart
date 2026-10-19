import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lejutv/components/webview/android_webview_component.dart';
import 'package:lejutv/components/webview/wk_webview_component.dart';
import 'package:lejutv/components/webview/windows_webview_component.dart';

typedef WebViewCallback = FutureOr<void> Function(String url);
typedef WebViewErrorCallback = FutureOr<void> Function(WebResourceError error);

/// Selects the platform implementation while keeping page call sites shared.
class WebViewComponent extends StatelessWidget {
  const WebViewComponent({
    super.key,
    this.initialUrl,
    this.onControllerReady,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebResourceError,
  });

  final String? initialUrl;
  final ValueChanged<WebViewController>? onControllerReady;
  final WebViewCallback? onPageStarted;
  final WebViewCallback? onPageFinished;
  final WebViewErrorCallback? onWebResourceError;

  @override
  Widget build(BuildContext context) {
    final component = switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidWebViewComponent(
        initialUrl: initialUrl,
        onControllerReady: onControllerReady,
        onPageStarted: onPageStarted,
        onPageFinished: onPageFinished,
        onWebResourceError: onWebResourceError,
      ),
      TargetPlatform.windows => WindowsWebViewComponent(
        initialUrl: initialUrl,
        onControllerReady: onControllerReady,
        onPageStarted: onPageStarted,
        onPageFinished: onPageFinished,
        onWebResourceError: onWebResourceError,
      ),
      TargetPlatform.iOS => WkWebViewComponent(
        initialUrl: initialUrl,
        onControllerReady: onControllerReady,
        onPageStarted: onPageStarted,
        onPageFinished: onPageFinished,
        onWebResourceError: onWebResourceError,
      ),
      _ => const Center(child: Text('当前平台暂不支持 WebView')),
    };
    return component;
  }
}
