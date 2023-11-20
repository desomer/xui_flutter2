import 'package:flutter/material.dart';

import 'widget_hub.dart';

class ImgImpl extends GetWidget {
  @override
  Widget getWidget(String url) {
    return Image.network(url, width: 200);
  }
}
