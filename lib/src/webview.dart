import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  InAppWebViewController? _controller;
  final browser = InAppBrowser();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        useOnLoadResource: true,
        allowFileAccess: true,
        allowUniversalAccessFromFileURLs: true,
        allowFileAccessFromFileURLs: true,
        allowContentAccess: true,
      ),
      initialUrlRequest: URLRequest(
        url: WebUri(
          '$widgetUrl/${widget.channelId}?mode=livechat&state=${widget.user != null ? 'off' : 'on'}',
        ),
      ),
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url!;
        if (!url.toString().contains('https://messenger.svc.chative.io')) {
          await browser.openUrlRequest(urlRequest: URLRequest(url: url));
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
      onWebViewCreated: (controller) {
        _controller = controller;

        // Thêm JavaScript Handler
        _controller?.addJavaScriptHandler(
          handlerName: 'FlutterWebView',
          callback: (args) {
            if (args.isNotEmpty && args[0] is String) {
              String message = args[0];
              Map<String, dynamic> parsedData;
              try {
                parsedData = jsonDecode(message);
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
                  widget.onError
                      ?.call(parsedData['message'] ?? 'Unknown error');
                  break;
                default:
                  break;
              }
            }
          },
        );
      },
      onLoadStart: (controller, url) {},
      onLoadStop: (controller, url) async {
        _controller?.evaluateJavascript(
            source: generateScriptGetError(widget.channelId));
        _controller?.evaluateJavascript(
            source: generateScript(widget.user ?? {}));
      },
      onConsoleMessage: (controller, consoleMessage) {},
      onReceivedError: (controller, request, error) {
        widget.onError?.call(error.description);
      },
      onReceivedHttpError: (controller, request, response) {
        widget.onError?.call(response.reasonPhrase ?? 'Unknown error');
      },
    );
  }

  Future<void> injectJavaScript(String script) async {
    if (_controller != null) {
      await _controller!.evaluateJavascript(source: script);
    }
  }

  Future<void> reload() async {
    if (_controller != null) {
      await _controller!.reload();
    }
  }
}
