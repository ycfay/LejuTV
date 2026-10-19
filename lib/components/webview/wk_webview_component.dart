import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lejutv/components/webview/webview_component.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WkWebViewComponent extends StatefulWidget {
  const WkWebViewComponent({
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
  State<WkWebViewComponent> createState() => _WkWebViewComponentState();
}

class _WkWebViewComponentState extends State<WkWebViewComponent> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final params = WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    );
    _controller = WebViewController.fromPlatformCreationParams(params);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(Colors.black);
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
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
