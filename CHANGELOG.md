## 0.0.1
- **Initial Release** of the [Chative.IO Flutter Widget](https://github.com/botstar/chative-flutter-sdk) on 2024-11-08.
- **Customizable Chat Interface**: Easily tailor the chat widget to match your app's design.
- **Programmatic Show/Hide**: Display or hide the chat widget using `ChativeWidgetController`.
- **Custom Header Components**: Integrate custom headers to enhance the chat experience.
- **User Information Integration**: Populate user details into live chat for personalized interactions.
- **Adjustable Insets**: Customize top and bottom insets to accommodate different device sizes.
- **Event Callbacks**:
  - `onClosed`: Triggered when the chat widget is closed.
  - `onLoaded`: Triggered when the chat widget is loaded.
  - `onNewMessage`: Triggered when a new message is received.
  - `onError`: Triggered when an error occurs within the chat widget.
- **Controller Methods**:
  - `show()`: Display the chat widget.
  - `hide()`: Hide the chat widget.
  - `injectJavascript(String script)`: Inject custom JavaScript into the chat widget.
  - `reload()`: Reload the chat widget.
  - `clearData()`: Clear data (localStorage) the chat widget


