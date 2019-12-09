import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
//    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> pickImage({int maxSize = 1, bool camera = false, bool crop = false}) async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      List<String> paths =
          await ImagePicker.pick(maxSize: maxSize, camera: camera, crop: crop);
      platformVersion = paths.join('\n');
      print(platformVersion);
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              RaisedButton(
                onPressed: () {
                  pickImage(camera: true);
                },
                child: Text('拍照'),
              ),
              RaisedButton(
                onPressed: () {
                  pickImage(camera: true, crop: true);
                },
                child: Text('拍照裁剪'),
              ),
              RaisedButton(
                onPressed: () {
                  pickImage(maxSize: 1);
                },
                child: Text('单选'),
              ),
              RaisedButton(
                onPressed: () {
                  pickImage(maxSize: 1, crop: true);
                },
                child: Text('单选裁剪'),
              ),
              RaisedButton(
                onPressed: () {
                  pickImage(maxSize: 3);
                },
                child: Text('多选'),
              ),
              Text('$_platformVersion')
            ],
          ),
        ),
      ),
    );
  }
}
