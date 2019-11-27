import 'dart:async';

import 'package:flutter/services.dart';

class ImagePicker {
  static const MethodChannel _channel =
      const MethodChannel('image_picker');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
