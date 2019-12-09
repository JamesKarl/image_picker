import 'dart:async';

import 'package:flutter/services.dart';

class ImagePicker {
  static const MethodChannel _channel = const MethodChannel('image_picker');

  static Future<List<String>> pick(
      {int maxSize = 1,
      bool camera = false,
      bool crop = false,
      int maxWidth,
      int maxHeight,
      int quality}) async {
    final List<dynamic> images = await _channel.invokeMethod('pickImage', {
      "maxSize": maxSize,
      "camera": camera,
      "crop": crop,
      "maxWidth": maxWidth,
      "maxHeight": maxHeight,
      "quality": quality,
    });
    return images.map((i) => '$i').toList();
  }
}
