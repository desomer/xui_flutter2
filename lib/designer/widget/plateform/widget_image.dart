import 'package:flutter/material.dart';
import 'widget_hub.dart';

// import 'widget_plateform.dart'
//     if (dart.library.html) 'widget_cors_image.dart';

import 'widget_cors_image.dart';    

class Plateform {
  final GetWidget _impl;

  Plateform() : _impl = ImgImpl();

  Widget getImage(String url) {
    return _impl.getWidget(url);
  }
}
