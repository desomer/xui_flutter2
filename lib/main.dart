// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:universal_html/html.dart' as html;
import 'package:xui_flutter/designer/application_manager.dart';
import 'core/store/driver.dart';
import 'core/widget/cw_core_widget.dart';
import 'designer/designer.dart';

class MyErrorsHandler {
  initialize() {}

  onErrorDetails(FlutterErrorDetails details) {
    //FlutterError.presentError(details);
    debugPrint('onErrorDetails ${details.summary}');
  }

  onError(Object error, StackTrace stack) {
    debugPrint('onError $error $stack');
  }
}

// mongo    gauthierdesomer   xRyLG1bVzc8IproW

void main() async {
  var myErrorsHandler = MyErrorsHandler();

  await myErrorsHandler.initialize();

  CWApplication.of().initDesigner();
  CWApplication.of().initModel();

  await StoreDriver.getDefautDriver("main");

  //*_r$y-74WSMFKk8
  //await supabase();

  //StartMongo().init();

  CoreDesigner();
  Widget view = CoreDesigner.of();
  bool m = false;
  if (m) {
    view = await CoreDesigner.of()
        .designView
        .getPageRoot(mode: ModeRendering.view);
  }

  runApp(view);

  html.document.onContextMenu
      .listen((html.MouseEvent event) => event.preventDefault());
  //runApp(const MyApp());
}

typedef OnWidgetSizeChange = void Function(Size size);

class WidgetSizeRenderObject extends RenderProxyBox {
  WidgetSizeRenderObject(this.onSizeChange);
  final OnWidgetSizeChange onSizeChange;
  Size? currentSize;

  @override
  void performLayout() {
    super.performLayout();

    try {
      Size? newSize = child?.size;

      if (newSize != null && currentSize != newSize) {
        currentSize = newSize;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onSizeChange(newSize);
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

class WidgetSizeOffsetWrapper extends SingleChildRenderObjectWidget {
  const WidgetSizeOffsetWrapper({
    super.key,
    required this.onSizeChange,
    required Widget super.child,
  });
  final OnWidgetSizeChange onSizeChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return WidgetSizeRenderObject(onSizeChange);
  }
}
