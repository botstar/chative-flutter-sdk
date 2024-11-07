import 'package:flutter/material.dart';
import 'package:chative_sdk/src/webview.dart';
import 'package:chative_sdk/src/utils.dart';

typedef OnClosed = void Function();
typedef OnLoaded = void Function();
typedef OnNewMessage = void Function();
typedef OnError = void Function(String message);

class ChativeWidgetController {
  late _ChativeWidgetState _state;

  void show() {
    _state.show();
  }

  void hide() {
    _state.hide();
  }

  Future<void> injectJavascript(String script) async {
    await _state.injectJavaScript(script);
  }

  Future<void> reload() async {
    await _state.reload();
  }
}

class ChativeWidget extends StatefulWidget {
  final ChativeWidgetController? controller;
  final String channelId;
  final Map<String, dynamic>? user;
  final Widget? headerComponent;
  final BoxDecoration? containerDecoration;
  final double insetTop;
  final double insetBottom;
  final OnClosed? onClosed;
  final OnLoaded? onLoaded;
  final OnNewMessage? onNewMessage;
  final OnError? onError;

  const ChativeWidget({
    super.key,
    required this.channelId,
    this.controller,
    this.user,
    this.headerComponent,
    this.containerDecoration,
    this.insetTop = 20,
    this.insetBottom = 20,
    this.onClosed,
    this.onLoaded,
    this.onNewMessage,
    this.onError,
  });

  @override
  State<ChativeWidget> createState() => _ChativeWidgetState();
}

class _ChativeWidgetState extends State<ChativeWidget> {
  bool isVisible = false;
  late ChativeWidgetController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? ChativeWidgetController();
    controller._state = this;
  }

  void show() {
    setState(() {
      isVisible = true;
    });
    injectJavaScript(widgetApi('openChatWindow', {}));
  }

  void handleClosed() {
    setState(() {
      isVisible = false;
    });
    injectJavaScript(widgetApi('openChatWindow', {}));
    if (widget.onClosed != null) widget.onClosed!();
  }

  void hide() {
    setState(() {
      isVisible = false;
    });
  }

  Future<void> reload() async {
    await _webViewKey.currentState?.reload();
  }

  Future<void> injectJavaScript(dynamic script) async {
    await _webViewKey.currentState?.injectJavaScript(script);
  }

  final GlobalKey<WebviewState> _webViewKey = GlobalKey<WebviewState>();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.insetTop,
      bottom: widget.insetBottom,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          ignoring: !isVisible,
          child: Container(
            decoration: widget.containerDecoration ??
                const BoxDecoration(
                  color: Colors.white,
                  // boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10),],
                ),
            child: Column(
              children: [
                if (widget.headerComponent != null) widget.headerComponent!,
                Expanded(
                  child: Webview(
                    key: _webViewKey,
                    channelId: widget.channelId,
                    user: widget.user,
                    onLoaded: widget.onLoaded,
                    onClosedWidget: handleClosed,
                    onNewMessage: widget.onNewMessage,
                    onError: widget.onError,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
