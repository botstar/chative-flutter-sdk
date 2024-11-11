import 'dart:convert';

import 'package:chative_sdk/src/constants.dart';

/// Generates the JavaScript script to be injected into the WebView
String generateScript(Map<String, dynamic> user) {
  String userString = jsonEncode(user);
  return '''
    window.cti_api = function (action, data) {
      if (window.ChativeApi) {
        window.ChativeApi(action, data);
      }

      window.ChativeEvents ||= [];
      window.ChativeEvents.push([action, data]);
    };

    const user = $userString;

    if (user.user_id) {
      window.cti_api('boot', user);
    }

    window.cti_api('openChatWindow');

    window.cti_api('addEventListener', { event: 'closed', callback: () => { 
      window.cti_api('hide'); 
      window.FlutterWebView.postMessage(JSON.stringify({ event: 'closed' })); 
    }});

    window.cti_api('addEventListener', { event: 'new-agent-message', callback: () => { 
      window.FlutterWebView.postMessage(JSON.stringify({ event: 'new-agent-message' })); 
    }});

    window.cti_api('addEventListener', { event: 'ready', callback: () => { 
      window.FlutterWebView.postMessage(JSON.stringify({ event: 'ready' })); 
    }});
  ''';
}

/// Generates the JavaScript script to be injected into the WebView to get the config
String generateScriptGetError(String channelId) {
  return '''
    function getTimeZone() {
      const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
      return timeZone;
    }
    (function() {
      fetch("$queryUrl", {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          "app_id": "$channelId",
          "user_id": "",
          "locale": "en-US",
          "timezone": getTimeZone(),
          "template": false,
          "host": "$widgetUrl/$channelId?mode=livechat"
        })
      }).then((response) => {
        if (response.status !== 200) {
          console.error('Error fetching config');
          window.FlutterWebView.postMessage(JSON.stringify({ event: 'error', message: 'missing_config' }));
        }
      }).catch((error) => {
        window.FlutterWebView.postMessage(JSON.stringify({ event: 'error', message: error.toString() }));
      });
    })();
  ''';
}

/// Converts a Dart object into a JavaScript object string
String widgetApi(String event, dynamic data) {
  String dataString;
  if (data is String) {
    dataString = "'$data'";
  } else {
    dataString = jsonEncode(data);
  }
  return '''
    window.cti_api('$event', $dataString);
  ''';
}

/// Utility function to check if a JavaScript script is safe for injection.
/// It scans the script for disallowed keywords and patterns.
/// Returns `true` if the script is considered safe, `false` otherwise.
bool isScriptSafe(String script) {
  // List of disallowed keywords and patterns
  final List<RegExp> disallowedPatterns = [
    RegExp(r'\beval\b', caseSensitive: false),
    RegExp(r'\bdocument\.cookie\b', caseSensitive: false),
    RegExp(r'\blocalStorage\b', caseSensitive: false),
    RegExp(r'\bsessionStorage\b', caseSensitive: false),
    RegExp(r'\bXMLHttpRequest\b', caseSensitive: false),
    RegExp(r'\bfetch\b', caseSensitive: false),
    RegExp(r'\bsetInterval\b', caseSensitive: false),
    RegExp(r'\bsetTimeout\b', caseSensitive: false),
    RegExp(r'\bFunction\b', caseSensitive: false),
    RegExp(r'\bimportScripts\b', caseSensitive: false),
    RegExp(r'\bWebSocket\b', caseSensitive: false),
    RegExp(r'\bpostMessage\b', caseSensitive: false),
    RegExp(r'\bwindow\.location\b', caseSensitive: false),
    RegExp(r'\bdocument\.write\b', caseSensitive: false),
    RegExp(r'\bdocument\.writeln\b', caseSensitive: false),
    RegExp(r'\balert\b', caseSensitive: false),
    RegExp(r'\bconfirm\b', caseSensitive: false),
    RegExp(r'\bprompt\b', caseSensitive: false),
    RegExp(r'\bconsole\.log\b', caseSensitive: false),
    RegExp(r'\bnew\s+Function\b', caseSensitive: false),
    RegExp(r'\bRegExp\b', caseSensitive: false),
  ];

  for (var pattern in disallowedPatterns) {
    if (pattern.hasMatch(script)) {
      return false;
    }
  }

  return true;
}

/// Safely parses a JSON string into a Map
Map<String, dynamic> parseJson(String message) {
  try {
    return jsonDecode(message) as Map<String, dynamic>;
  } catch (e) {
    return {};
  }
}
