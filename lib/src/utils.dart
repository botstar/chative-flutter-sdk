import 'dart:convert';

import 'package:chative_sdk/src/constants.dart';

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
      window.flutter_inappwebview.callHandler('FlutterWebView', JSON.stringify({ event: 'closed' })); 
    }});

    window.cti_api('addEventListener', { event: 'new-agent-message', callback: () => { 
      window.flutter_inappwebview.callHandler('FlutterWebView', JSON.stringify({ event: 'new-agent-message' })); 
    }});

    window.cti_api('addEventListener', { event: 'ready', callback: () => { 
      window.flutter_inappwebview.callHandler('FlutterWebView', JSON.stringify({ event: 'ready' })); 
    }});
  ''';
}

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
          window.flutter_inappwebview.callHandler('FlutterWebView', JSON.stringify({ event: 'error', message: 'missing_config' }));
        }
      }).catch((error) => {
        window.flutter_inappwebview.callHandler('FlutterWebView', JSON.stringify({ event: 'error', message: error.toString() }));
      });
    })();
  ''';
}

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
