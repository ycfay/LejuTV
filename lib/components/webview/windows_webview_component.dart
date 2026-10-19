import 'dart:async';
import 'dart:typed_data';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:lejutv/components/webview/webview_component.dart';
import 'package:webview_flutter/webview_flutter.dart' as flutter_webview;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class WindowsWebViewComponent extends StatefulWidget {
  const WindowsWebViewComponent({
    super.key,
    this.initialUrl,
    this.onControllerReady,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebResourceError,
  });

  final String? initialUrl;
  final ValueChanged<flutter_webview.WebViewController>? onControllerReady;
  final WebViewCallback? onPageStarted;
  final WebViewCallback? onPageFinished;
  final WebViewErrorCallback? onWebResourceError;

  @override
  State<WindowsWebViewComponent> createState() =>
      _WindowsWebViewComponentState();
}

class _WindowsWebViewComponentState extends State<WindowsWebViewComponent> {
  Webview? _webview;
  _WindowsController? _controller;
  StreamSubscription<WebviewLoadError>? _errorSubscription;
  String? _lastUrl;
  bool _wasLoading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      if (!await WebviewWindow.isWebviewAvailable()) {
        throw StateError('WebView2 Runtime is not available');
      }
      final webview = await WebviewWindow.create(
        configuration: const CreateConfiguration(
          openMaximized: true,
          titleBar: TitleBarOptions(showNavigation: false, showReload: false),
        ),
      );
      if (!mounted) {
        await webview.close();
        return;
      }

      _webview = webview;
      _controller = _WindowsController(webview);
      webview.navigationState.addListener(_handleNavigationState);
      _errorSubscription = webview.onLoadError.listen((error) {
        widget.onWebResourceError?.call(
          flutter_webview.WebResourceError(
            errorCode: -1,
            description: error.description,
            isForMainFrame: true,
            url: error.url,
          ),
        );
      });

      widget.onControllerReady?.call(_controller!);
      final initialUrl = widget.initialUrl;
      if (initialUrl != null) {
        await _controller!.loadRequest(Uri.parse(initialUrl));
      }
    } catch (error, stackTrace) {
      debugPrint('Windows WebView initialization failed: $error\n$stackTrace');
      if (mounted) {
        widget.onWebResourceError?.call(
          flutter_webview.WebResourceError(
            errorCode: -1,
            description: error.toString(),
            isForMainFrame: true,
          ),
        );
      }
    }
  }

  void _handleNavigationState() {
    final state = _webview?.navigationState.value;
    if (state == null) return;
    final url = state.url ?? _lastUrl ?? '';
    if (state.isLoading && (!_wasLoading || url != _lastUrl)) {
      widget.onPageStarted?.call(url);
    } else if (!state.isLoading && (_wasLoading || url != _lastUrl)) {
      widget.onPageFinished?.call(url);
    }
    _wasLoading = state.isLoading;
    _lastUrl = state.url;
  }

  @override
  void dispose() {
    final webview = _webview;
    if (webview != null) {
      webview.navigationState.removeListener(_handleNavigationState);
      unawaited(webview.close());
    }
    unawaited(_errorSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

/// Adapts the API used by the pages to the separate native Windows window.
class _WindowsController extends flutter_webview.WebViewController {
  _WindowsController(this._webview)
    : super.fromPlatform(_WindowsPlatformController());

  final Webview _webview;

  @override
  Future<void> loadRequest(
    Uri uri, {
    flutter_webview.LoadRequestMethod method =
        flutter_webview.LoadRequestMethod.get,
    Map<String, String> headers = const <String, String>{},
    Uint8List? body,
  }) async {
    if (method != flutter_webview.LoadRequestMethod.get ||
        headers.isNotEmpty ||
        body != null) {
      throw UnsupportedError('Windows WebView supports GET requests only.');
    }
    await _webview.launch(uri.toString());
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    await _webview.evaluateJavaScript(javaScript);
  }
}

/// The Flutter controller requires a platform controller at construction.
/// Windows operations are handled by [_WindowsController] and the native
/// desktop webview, so this placeholder must never receive platform calls.
class _WindowsPlatformController extends PlatformWebViewController {
  _WindowsPlatformController()
    : super.implementation(const PlatformWebViewControllerCreationParams());
}
