import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_widget.dart';
import '../core/widget/cw_factory.dart';
import 'designer.dart';
import 'widget_properties.dart';
import 'form_builder.dart';
import '../core/widget/cw_core_selector.dart';

class CoreDataSelector {
  static List<Widget> listProp = [];

  CoreDataEntity getEmptyEntity(DesignCtx ctx) {
    ctx.factory = ctx.widget!.ctx.factory;
    CoreDataPath? path =
        ctx.factory?.root!.getPath(ctx.factory!.collection, ctx.pathCreate!);
    //String type = path!.entities.last.getType(null, path.entities.last.value);
    String impl = path!.entities.last.value['implement'];
    CoreDataEntity emptyEntity = ctx.factory!.collection.createEntity(impl);
    return emptyEntity;
  }

  doSelectWidget(SelectorWidget slot, int buttonId) {
    String pathWidget = slot.ctx.pathWidget;
    CoreDataSelector.listProp.clear();

    // print('mapWidgetByXid ${slot.ctx.factory.mapWidgetByXid}');
    // print('mapXidByPath ${slot.ctx.factory.mapXidByPath}');

    while (pathWidget.isNotEmpty) {
      DesignCtx ctx = DesignCtx();
      ctx.pathWidget = pathWidget;

      ctx.xid = slot.ctx.factory.mapXidByPath[pathWidget];
      ctx.widget = slot.ctx.factory.mapWidgetByXid[ctx.xid];

      // String prop = 'no child';
      // if (ctx.widget != null) {
      //   // test si cmp dans slot
      //   prop = ctx.widget!.ctx.entity?.value.toString() ?? 'no prop';
      // }

      ctx.pathDesign = ctx.widget?.ctx.pathDataDesign;
      ctx.pathCreate = ctx.widget?.ctx.pathDataCreate;

      if (ctx.widget == null) {
        debugPrint('>>> $pathWidget as empty slot');
      } else {
        ctx.factory = ctx.widget!.ctx.factory;
        ctx.collection = ctx.widget!.ctx.factory.collection;
        ctx.mode = ModeRendering.view;
        if (ctx.widget!.ctx.entity == null) {
          ctx.entity = getEmptyEntity(ctx);
          listProp.addAll(FormBuilder().getFormWidget(ctx));
        } else {
          ctx.entity = ctx.widget!.ctx.entity!;
          listProp.addAll(FormBuilder().getFormWidget(ctx));
        }
        // debugPrint(
        //     '>>> $pathWidget as $w<xid=${w.ctx.xid}> create by $pathCreate design by $pathDesign with $prop ');
      }
      int i = pathWidget.lastIndexOf('.');
      if (i < 0) break;
      pathWidget = pathWidget.substring(0, i);
    }

    DesignerPropState? state =
        CoreDesigner.propKey.currentState as DesignerPropState?;

    // ignore: invalid_use_of_protected_member
    state?.setState(() {});

    // debugPrint(
    //     'Clicked gesture ${slot.ctx.pathWidget}  $buttonId ${slot.ctx.xid}');
  }
}

class DesignCtx {
  String? pathWidget;
  String? xid;
  CWWidget? widget;
  String? pathDesign;
  String? pathCreate;
  late CoreDataCollection collection;
  WidgetFactoryEventHandler? factory;
  late CoreDataEntity entity;
  late ModeRendering mode;
}
