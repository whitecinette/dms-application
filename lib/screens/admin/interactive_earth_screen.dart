import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InteractiveEarthScreen extends StatefulWidget {
  const InteractiveEarthScreen({Key? key}) : super(key: key);

  @override
  State<InteractiveEarthScreen> createState() => _InteractiveEarthScreenState();
}

class _InteractiveEarthScreenState extends State<InteractiveEarthScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterWebviewPlugin',
        onMessageReceived: (message) {
          print('JavaScript sent: ${message.message}');
          // You can now trigger UI updates, alerts, navigation, etc.
        },
      )
      ..loadFlutterAsset('assets/earth.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('3D Earth View')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
