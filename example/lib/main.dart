import 'package:flutter/material.dart';
import 'package:chative_sdk/chative_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ChativeWidgetController _controller = ChativeWidgetController();

  final channelId = 'YOUR_CHANNEL_ID';
  final user = {
    'user_id': 'UNIQUE_USER_ID',
    'user': {
      'email': 'abc@gmail.com',
      'first_name': 'Chative',
      'last_name': 'User',
      'phone': '1234567890',
    },
  };

  void _ShowChat() {
    _controller.show();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                _controller.show();
              },
              child: Text('Show Chat Widget'),
            ),
          ),
          ChativeWidget(
            channelId: channelId,
            controller: _controller,
            user: user,
            insetTop: 50,
            // insetBottom: 50,
            //@ You can also add a header component to the chat widget
            // headerComponent: Container(
            //   color: Colors.blue,
            //   height: 50,
            //   child: Center(
            //     child: Text(
            //       'Chative Widget Header',
            //       style: TextStyle(
            //         color: Colors.white,
            //         fontSize: 20,
            //       ),
            //     ),
            //   ),
            // ),
            onClosed: () {
              print('Chat widget closed');
            },
            onLoaded: () {
              print('Chat widget loaded');
            },
            onNewMessage: () {
              print('New message received');
            },
            onError: (message) {
              print('Error: $message');
            },
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _ShowChat,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
