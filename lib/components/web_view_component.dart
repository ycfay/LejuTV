import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef WebViewCallback = FutureOr<void> Function(String url);
typedef WebViewErrorCallback = FutureOr<void> Function(WebResourceError error);

/// Shared WebView setup used by all pages in the app.
class WebViewComponent extends StatefulWidget {
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
  State<WebViewComponent> createState() => _WebViewComponentState();
}

class _WebViewComponentState extends State<WebViewComponent> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(Colors.black);
    await _controller.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/116.0.0.0 Safari/537.36',
    );

    final platformController = _controller.platform;
    if (platformController is AndroidWebViewController) {
      await platformController.setUseWideViewPort(true);
      await platformController.enableZoom(false);
      await platformController.setMediaPlaybackRequiresUserGesture(false);
    }

    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) => widget.onPageStarted?.call(url),
        onPageFinished: (url) => widget.onPageFinished?.call(url),
        onWebResourceError: (error) {
          debugPrint('失败 URL: ${error.url}');
          debugPrint('错误码: ${error.errorCode}');
          debugPrint('错误描述: ${error.description}');
          debugPrint('主页面错误: ${error.isForMainFrame}');
          widget.onWebResourceError?.call(error);
        },
      ),
    );

    widget.onControllerReady?.call(_controller);
    final initialUrl = widget.initialUrl;
    if (initialUrl != null) {
      await _controller.loadRequest(Uri.parse(initialUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
