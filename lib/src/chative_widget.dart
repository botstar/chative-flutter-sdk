import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:chative_sdk/src/webview.dart';
import 'package:chative_sdk/src/utils.dart';

typedef OnClosed = void Function();
typedef OnLoaded = void Function();
typedef OnNewMessage = void Function();
typedef OnError = void Function(String message);

/// Controller for managing the ChativeWidget's state and interactions
class ChativeWidgetController {
  _ChativeWidgetState? _state;
  final Queue<Function> _actionQueue = Queue<Function>();

  /// Sets the state of the ChativeWidget
  void _setState(_ChativeWidgetState state) {
    _state = state;
    _processQueue();
  }

  /// Processes the action queue
  void _processQueue() {
    while (_actionQueue.isNotEmpty) {
      final action = _actionQueue.removeFirst();
      action();
    }
  }

  /// Enqueues an action to be executed when the state is set
  void _enqueueOrExecute(Function action) {
    if (_state != null) {
      action();
    } else {
      _actionQueue.add(action);
    }
  }

  /// Function to show the ChativeWidget
  void show() {
    _enqueueOrExecute(() {
      _state!.show();
    });
  }

  /// Function to hide the ChativeWidget
  void hide() {
    _enqueueOrExecute(() {
      _state!.hide();
    });
  }

  /// Inject JavaScript code into the WebView
  Future<void> injectJavascript(String script) async {
    _enqueueOrExecute(() async {
      await _state!.injectJavaScript(script);
    });
  }

  /// Reloads the WebView content
  Future<void> reload() async {
    _enqueueOrExecute(() async {
      await _state!.reload();
    });
  }

  /// Clears the WebView's local storage
  Future<void> clearData() async {
    _enqueueOrExecute(() async {
      await _state!.clearLocalStorage();
    });
  }
}

/// A StatefulWidget that displays a chat interface using WebView
class ChativeWidget extends StatefulWidget {
  final ChativeWidgetController? controller;

  /// The channel ID to be used for the chat widget
  final String channelId;

  /// The user data to be passed to the chat widget
  final Map<String, dynamic>? user;

  /// The widget to be displayed as the header of the chat widget
  final Widget? headerWidget;

  /// The decoration to be applied to the chat widget container
  final BoxDecoration? containerDecoration;

  /// The top inset of the chat widget
  final double insetTop;

  /// The bottom inset of the chat widget
  final double insetBottom;

  /// Callback function to be called when the chat widget is closed
  final OnClosed? onClosed;

  /// Callback function to be called when the chat widget is loaded
  final OnLoaded? onLoaded;

  /// Callback function to be called when a new message is received
  final OnNewMessage? onNewMessage;

  /// Callback function to be called when an error occurs
  final OnError? onError;

  const ChativeWidget({
    super.key,
    required this.channelId,
    this.controller,
    this.user,
    this.headerWidget,
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
  late ChativeWidgetController _controller;

  /// Key to access the WebViewState
  final GlobalKey<WebviewState> _webViewKey = GlobalKey<WebviewState>();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  /// Initializes the controller, either using the provided one or creating a new instance
  void _initializeController() {
    _controller = widget.controller ?? ChativeWidgetController();
    _controller._setState(this);
  }

  /// Shows the chat widget and sends a command to open the chat window
  void show() {
    setState(() {
      isVisible = true;
    });
    injectJavaScript(widgetApi('openChatWindow', {}));
  }

  /// Hides the chat widget and sends a command to close the chat window
  void hide() {
    setState(() {
      isVisible = false;
    });
  }

  /// Handles the closure of the chat widget
  void handleClosed() {
    setState(() {
      isVisible = false;
    });
    injectJavaScript(widgetApi('openChatWindow', {}));
    if (widget.onClosed != null) widget.onClosed!();
  }

  /// Reloads the WebView content
  Future<void> reload() async {
    await _webViewKey.currentState?.reload();
  }

  /// Injects JavaScript code into the WebView
  Future<void> injectJavaScript(dynamic script) async {
    if (isScriptSafe(script)) {
      await _webViewKey.currentState?.injectJavaScript(script);
    } else {
      widget.onError?.call('unsafe_script');
    }
  }

  /// Clears the WebView's local storage and reloads the content
  Future<void> clearLocalStorage() async {
    await _webViewKey.currentState?.clearLocalStorage();
  }

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
                ),
            child: Column(
              children: [
                if (widget.headerWidget != null) widget.headerWidget!,
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
