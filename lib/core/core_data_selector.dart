import 'package:flutter/material.dart';

import '../widget/cw_core_selector.dart';
import '../widget/cw_core_widget.dart';

class CoreDataSelector {
  setWidgetPath(SelectorWidget slot, int buttonId) {
    String path = slot.ctx.pathWidget;

    print('mapWidgetByXid ${slot.ctx.factory.mapWidgetByXid}');
    print('mapXidByPath ${slot.ctx.factory.mapXidByPath}');

    while (path.isNotEmpty) {
      final xid = slot.ctx.factory.mapXidByPath[path];
      final w = slot.ctx.factory.mapWidgetByXid[xid];

      String prop = 'no child';
      if (w != null) {
        // test si cmp dans slot
        prop = w.ctx.entity?.value.toString() ?? 'no prop';
      }

      String?  pathDesign = w?.ctx.pathDataDesign;
      String? pathCreate = w?.ctx.pathDataCreate;

      print('path selected $path $w<xid=${w?.ctx.xid}> pd=$pathDesign pc=$pathCreate prop=$prop');
      int i = path.lastIndexOf('.');
      if (i < 0) break;
      path = path.substring(0, i);
    }

    debugPrint(
        'Clicked gesture ${slot.ctx.pathWidget}  $buttonId ${slot.ctx.xid}');
  }
}
