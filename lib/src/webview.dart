import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'
    as webview_flutter_android;

import 'package:chative_sdk/src/constants.dart';
import 'package:chative_sdk/src/utils.dart';

typedef OnClosed = void Function();
typedef OnLoaded = void Function();
typedef OnNewMessage = void Function();
typedef OnError = void Function(String message);

class Webview extends StatefulWidget {
  final String channelId;
  final Map<String, dynamic>? user;
  final OnLoaded? onLoaded;
  final OnClosed? onClosedWidget;
  final OnNewMessage? onNewMessage;
  final OnError? onError;

  const Webview({
    Key? key,
    required this.channelId,
    this.user,
    this.onLoaded,
    this.onClosedWidget,
    this.onNewMessage,
    this.onError,
  }) : super(key: key);

  @override
  State<Webview> createState() => WebviewState();
}

class WebviewState extends State<Webview> {
  late final WebViewController _controller;
  WebViewController? _externalController;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  /// Initializes the WebViewController with initial configurations
  void _initializeController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(false)
      ..addJavaScriptChannel(
        'FlutterWebView',
        onMessageReceived: _handleJavaScriptMessage,
      )
      ..setNavigationDelegate(_createNavigationDelegate())
      ..loadRequest(_buildInitialUri());

    _configureFilePicker(_controller);
  }

  /// Builds the initial URI to load in the WebView
  Uri _buildInitialUri() {
    final state = widget.user != null ? 'off' : 'on';
    return Uri.parse(
        '$widgetUrl/site/${widget.channelId}?mode=livechat&state=$state');
  }

  /// Handles JavaScript messages received from the WebView
  void _handleJavaScriptMessage(JavaScriptMessage message) {
    final parsedData = _parseJson(message.message);

    switch (parsedData['event']) {
      case 'closed':
        widget.onClosedWidget?.call();
        break;
      case 'new-agent-message':
        widget.onNewMessage?.call();
        break;
      case 'ready':
        widget.onLoaded?.call();
        break;
      case 'error':
        widget.onError?.call(parsedData['message'] ?? 'Unknown error');
        break;
      default:
        // Do nothing for unrecognized events
        break;
    }
  }

  /// Safely parses a JSON string into a Map
  Map<String, dynamic> _parseJson(String message) {
    try {
      return jsonDecode(message) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Creates a NavigationDelegate for the WebView
  NavigationDelegate _createNavigationDelegate() {
    return NavigationDelegate(
      onNavigationRequest: _handleNavigationRequest,
      onPageFinished: _onPageFinished,
      onWebResourceError: _handleWebResourceError,
    );
  }

  /// Handles navigation requests within the WebView
  Future<NavigationDecision> _handleNavigationRequest(
      NavigationRequest request) async {
    if (!request.url.contains(widgetUrl)) {
      _showExternalWebView(request.url);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  /// Called when the page has finished loading
  Future<void> _onPageFinished(String url) async {
    await _controller.runJavaScript(generateScriptGetError(widget.channelId));
    await _controller.runJavaScript(generateScript(widget.user ?? {}));
  }

  /// Handles web resource errors
  void _handleWebResourceError(WebResourceError error) {
    widget.onError?.call(error.description);
  }

  /// Configures the file picker for Android
  Future<void> _configureFilePicker(WebViewController controller) async {
    if (Platform.isAndroid) {
      final androidController = controller.platform
          as webview_flutter_android.AndroidWebViewController;
      await androidController.setOnShowFileSelector(_androidFilePicker);
    }
  }

  /// Handles file selection on Android
  Future<List<String>> _androidFilePicker(
      webview_flutter_android.FileSelectorParams params) async {
    final fileType = _determineFileType(params.acceptTypes);
    final allowedExtensions = _extractAllowedExtensions(params.acceptTypes);

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: fileType,
        allowedExtensions: allowedExtensions?.toSet().toList(),
      );

      if (result != null && result.paths.isNotEmpty) {
        return result.paths
            .whereType<String>()
            .map((path) => Uri.file(path).toString())
            .toList();
      }
    } catch (e) {
      widget.onError?.call('Error picking file: $e');
    }

    return [];
  }

  /// Determines the file type based on MIME types
  FileType _determineFileType(List<String> acceptTypes) {
    for (var accept in acceptTypes) {
      if (accept.contains('*')) return FileType.custom;
    }
    return FileType.any;
  }

  /// Extracts allowed file extensions based on MIME types
  List<String>? _extractAllowedExtensions(List<String> acceptTypes) {
    final extensions = <String>[];

    for (var accept in acceptTypes) {
      for (var mime in accept.split(',')) {
        switch (mime.trim()) {
          case 'image/*':
            extensions.addAll(['jpg', 'jpeg', 'png', 'gif']);
            break;
          case 'application/pdf':
            extensions.add('pdf');
            break;
          case 'application/msword':
          case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
            extensions.addAll(['doc', 'docx']);
            break;
          default:
            break;
        }
      }
    }

    return extensions.isNotEmpty ? extensions : null;
  }

  /// Displays an external WebView when the URL is outside the widgetUrl
  void _showExternalWebView(String url) {
    _externalController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog.fullscreen(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(child: WebViewWidget(controller: _externalController!)),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the AppBar for the external WebView
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }

  /// Injects JavaScript into the WebView
  Future<void> injectJavaScript(String script) async {
    await _controller.runJavaScript(script);
  }

  /// Reloads the WebView
  Future<void> reload() async {
    await _controller.reload();
  }

  /// Clears the local storage of the WebView
  Future<void> clearLocalStorage() async {
    await _controller.runJavaScript('localStorage.clear();');
    await reload();
  }
}
