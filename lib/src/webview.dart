import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
    super.key,
    required this.channelId,
    this.user,
    this.onLoaded,
    this.onClosedWidget,
    this.onNewMessage,
    this.onError,
  });

  @override
  State<Webview> createState() => WebviewState();
}

class WebviewState extends State<Webview> {
  late final WebViewController _controller;
  WebViewController? _externalController;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(false)
      ..addJavaScriptChannel(
        'FlutterWebView',
        onMessageReceived: (JavaScriptMessage message) {
          Map<String, dynamic> parsedData;
          try {
            parsedData = jsonDecode(message.message);
          } catch (e) {
            parsedData = {};
          }

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
              break;
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            if (!request.url.contains(widgetUrl)) {
              _showExternalWebView(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) async {
            await _controller
                .runJavaScript(generateScriptGetError(widget.channelId));
            await _controller.runJavaScript(generateScript(widget.user ?? {}));
          },
          onWebResourceError: (WebResourceError error) {
            widget.onError?.call(error.description);
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          '$widgetUrl/site/${widget.channelId}?mode=livechat&state=${widget.user != null ? 'off' : 'on'}',
        ),
      );
  }

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              Expanded(
                child: WebViewWidget(
                  controller: _externalController!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }

  Future<void> injectJavaScript(String script) async {
    await _controller.runJavaScript(script);
  }

  Future<void> reload() async {
    await _controller.reload();
  }

  Future<void> clearLocalStorage() async {
    await _controller.runJavaScript('localStorage.clear();');
    await reload();
  }
}
