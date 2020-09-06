import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity/connectivity.dart';

String selectedUrl = 'https://nw3ke.csb.app';
String dev_ID = "edd67iJkn2KvUu77AH4BQf";
bool notFirstLoad = false;
String uid = '';
Future<String> _uid;

// ignore: prefer_collection_literals
final Set<JavascriptChannel> jsChannels = [
  JavascriptChannel(
      name: 'Print',
      onMessageReceived: (JavascriptMessage message) {
        print(message.message);
      }),
].toSet();

_launchURL(url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

void runAppMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final flutterWebViewPlugin = FlutterWebviewPlugin();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (_) => const MyHomePage(title: 'Flutter WebView'),
        '/widget': (_) {
          return WebviewScaffold(
            url: selectedUrl,
            javascriptChannels: jsChannels,
            mediaPlaybackRequiresUserGesture: false,
            appBar: AppBar(
              title: const Text('Widget WebView'),
            ),
            withZoom: true,
            withLocalStorage: true,
            hidden: true,
            initialChild: Container(
              color: Colors.redAccent,
              child: const Center(
                child: Text('Waiting.....'),
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      flutterWebViewPlugin.goBack();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {
                      flutterWebViewPlugin.goForward();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.autorenew),
                    onPressed: () {
                      flutterWebViewPlugin.reload();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Map _source = {ConnectivityResult.none: false};
  // MyConnectivity _connectivity = MyConnectivity.instance;
  // Instance of WebView plugin
  final flutterWebViewPlugin = FlutterWebviewPlugin();

  var asyncWidget;

  // AppsFlyerPlugin
  AppsflyerSdk _appsflyerSdk;

  // On destroy stream
  StreamSubscription _onDestroy;

  // On urlChanged stream
  StreamSubscription<String> _onUrlChanged;

  // On urlChanged stream
  StreamSubscription<WebViewStateChanged> _onStateChanged;

  StreamSubscription<WebViewHttpError> _onHttpError;

  StreamSubscription<double> _onProgressChanged;

  StreamSubscription<double> _onScrollYChanged;

  StreamSubscription<double> _onScrollXChanged;

  final _urlCtrl = TextEditingController(text: selectedUrl);

  final _codeCtrl = TextEditingController(text: 'window.navigator.userAgent');

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _history = [];

  @override
  void initState() {
    super.initState();

    final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: "edd67iJkn2KvUu77AH4BQf",
        appId: "WebViewMaster",
        showDebug: true);

    _appsflyerSdk = AppsflyerSdk(options);

    // _connectivity.initialise();
    // _connectivity.myStream.listen((source) {
    //   setState(() => _source = source);
    // });

    flutterWebViewPlugin.close();

    _urlCtrl.addListener(() {
      selectedUrl = _urlCtrl.text;
    });

    // Add a listener to on destroy WebView, so you can make came actions.
    _onDestroy = flutterWebViewPlugin.onDestroy.listen((_) {
      if (mounted) {
        // Actions like show a info toast.
        _scaffoldKey.currentState.showSnackBar(
            const SnackBar(content: const Text('Webview Destroyed')));
      }
    });

    // Add a listener to on url changed
    _onUrlChanged = flutterWebViewPlugin.onUrlChanged.listen((String url) {
      if (mounted) {
        setState(() {
          if ((url.contains('nw3ke')) || (url.startsWith('file:///'))) {
            print('onUrlChanged: $url');
          } else {
            _launchURL(url);
            flutterWebViewPlugin.goBack();
          }
        });
      }
    });

    _onProgressChanged =
        flutterWebViewPlugin.onProgressChanged.listen((double progress) {
      if (mounted) {
        setState(() {
          _history.add('onProgressChanged: $progress');
        });
      }
    });

    _onScrollYChanged =
        flutterWebViewPlugin.onScrollYChanged.listen((double y) {
      if (mounted) {
        setState(() {
          _history.add('Scroll in Y Direction: $y');
        });
      }
    });

    _onScrollXChanged =
        flutterWebViewPlugin.onScrollXChanged.listen((double x) {
      if (mounted) {
        setState(() {
          _history.add('Scroll in X Direction: $x');
        });
      }
    });

    _onStateChanged =
        flutterWebViewPlugin.onStateChanged.listen((WebViewStateChanged state) {
      if (mounted) {
        setState(() {
          _history.add('onStateChanged: ${state.type} ${state.url}');
        });
      }
    });

    _onHttpError =
        flutterWebViewPlugin.onHttpError.listen((WebViewHttpError error) {
      if (mounted) {
        setState(() {
          _history.add('onHttpError: ${error.code} ${error.url}');
        });
      }
    });
  }

  Future _getAsyncUID() async {
    Future<String> result = _appsflyerSdk.getAppsFlyerUID();
    print(result);
    return result;
  }

  Future<String> _getUID() async {
    uid = await _getAsyncUID();
    print('uid=' + uid);
    return uid;
  }

  // @override
  Widget build(BuildContext context) {
    //   // if (notFirstLoad) {
    //   //   switch (_source.keys.toList()[0]) {
    //   //     case ConnectivityResult.none:
    //   //       flutterWebViewPlugin
    //   //           .launch('file:///android_asset/flutter_assets/assets/index.html');
    //   //       print('ConnectivityResult.NONE');
    //   //       break;
    //   //     case ConnectivityResult.mobile:
    //   //       flutterWebViewPlugin.launch(selectedUrl);
    //   //       print('ConnectivityResult.mobile');
    //   //       break;
    //   //     case ConnectivityResult.wifi:
    //   //       print('ConnectivityResult.wifi');
    //   //       flutterWebViewPlugin.launch(selectedUrl);
    //   //   }
    //   // }
    //   // notFirstLoad = true;

    if (!(notFirstLoad)) {
      _getUID().then((value) {
        setState(() {
          uid = value;
        });
      });

      if (uid == '') {
        print('Loading');
        return MaterialApp(home: Scaffold());
      } else {
        notFirstLoad = true;
        print(uid);
        print('URL=' + selectedUrl + uid);
        flutterWebViewPlugin.launch(selectedUrl + uid);
      }
    } else {
      return MaterialApp(home: Scaffold(body: Text('MAIN APP')));
    }
  }

  @override
  void dispose() {
    //_connectivity.disposeStream();

    _onDestroy.cancel();
    _onUrlChanged.cancel();
    _onStateChanged.cancel();
    _onHttpError.cancel();
    _onProgressChanged.cancel();
    _onScrollXChanged.cancel();
    _onScrollYChanged.cancel();

    flutterWebViewPlugin.dispose();

    super.dispose();
  }
}

// class MyConnectivity {
//   MyConnectivity._internal();

//   static final MyConnectivity _instance = MyConnectivity._internal();

//   static MyConnectivity get instance => _instance;

//   Connectivity connectivity = Connectivity();

//   StreamController controller = StreamController.broadcast();

//   Stream get myStream => controller.stream;

//   void initialise() async {
//     ConnectivityResult result = await connectivity.checkConnectivity();
//     _checkStatus(result);
//     connectivity.onConnectivityChanged.listen((result) {
//       _checkStatus(result);
//     });
//   }

//   void _checkStatus(ConnectivityResult result) async {
//     bool isOnline = false;
//     try {
//       final result = await InternetAddress.lookup('example.com');
//       if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
//         isOnline = true;
//       } else
//         isOnline = false;
//     } on SocketException catch (_) {
//       isOnline = false;
//     }
//     controller.sink.add({result: isOnline});
//   }

//   void disposeStream() => controller.close();
// }
