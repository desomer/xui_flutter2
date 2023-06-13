import 'package:flutter/material.dart';

import '../../designer/designer.dart';
import '../../designer/designerProp.dart';
import '../../designer/prop_designer.dart';
import '../widget/cw_core_selector.dart';

class CoreDataSelector {
  doSelectWidget(SelectorWidget slot, int buttonId) {
    String path = slot.ctx.pathWidget;

    // print('mapWidgetByXid ${slot.ctx.factory.mapWidgetByXid}');
    // print('mapXidByPath ${slot.ctx.factory.mapXidByPath}');

    List<Widget> listProp = [];

    while (path.isNotEmpty) {
      final xid = slot.ctx.factory.mapXidByPath[path];
      final w = slot.ctx.factory.mapWidgetByXid[xid];

      String prop = 'no child';
      if (w != null) {
        // test si cmp dans slot
        prop = w.ctx.entity?.value.toString() ?? 'no prop';
      }

      String? pathDesign = w?.ctx.pathDataDesign;
      String? pathCreate = w?.ctx.pathDataCreate;

      if (w == null) {
        debugPrint('>>> $path as empty slot');
      } else {
        if (w.ctx.entity != null) {
          listProp.addAll(FormBuilder()
              .getFormWidget(w.ctx.factory.collection, w.ctx.entity!));
        }
        debugPrint(
            '>>> $path as $w<xid=${w.ctx.xid}> create by $pathCreate design by $pathDesign with $prop ');
      }
      int i = path.lastIndexOf('.');
      if (i < 0) break;
      path = path.substring(0, i);
    }

    DesignerPropDartState state =
        CoreDesigner.propKey.currentState as DesignerPropDartState;
    state.setProp(listProp);
    // debugPrint(
    //     'Clicked gesture ${slot.ctx.pathWidget}  $buttonId ${slot.ctx.xid}');
  }
}
