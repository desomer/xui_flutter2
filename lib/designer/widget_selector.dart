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
    CoreDataPath? path = ctx.factory?.cwFactory!
        .getPath(ctx.factory!.collection, ctx.pathCreate!);
    //String type = path!.entities.last.getType(null, path.entities.last.value);
    String impl = path!.entities.last.value['implement'];
    CoreDataEntity emptyEntity = ctx.factory!.collection.createEntity(impl);
    return emptyEntity;
  }

  doSelectWidget(SelectorWidget slot, int buttonId) {
    String pathWidget = slot.ctx.pathWidget;
    CoreDataSelector.listProp.clear();

    while (pathWidget.isNotEmpty) {
      DesignCtx aCtx = DesignCtx();
      aCtx.pathWidget = pathWidget;
      aCtx.xid = slot.ctx.factory.mapXidByPath[pathWidget];
      aCtx.widget = slot.ctx.factory.mapWidgetByXid[aCtx.xid];
      aCtx.pathDesign = aCtx.widget?.ctx.pathDataDesign;
      aCtx.pathCreate = aCtx.widget?.ctx.pathDataCreate;

      if (aCtx.widget == null) {
        debugPrint('>>> $pathWidget as empty slot');
      } else {
        aCtx.factory = aCtx.widget!.ctx.factory;
        aCtx.collection = aCtx.widget!.ctx.factory.collection;
        aCtx.mode = ModeRendering.view;
        if (aCtx.widget!.ctx.entityForFactory == null) {
          var prop = getEmptyEntity(aCtx);
          prop.custom["onMap"] = MapDesign(aCtx);
          listProp.addAll(FormBuilder().getFormWidget(aCtx, prop));
        } else {
          listProp.addAll(FormBuilder()
              .getFormWidget(aCtx, aCtx.widget!.ctx.entityForFactory!));
        }
      }
      int i = pathWidget.lastIndexOf('.');
      if (i < 0) break;
      pathWidget = pathWidget.substring(0, i);
    }

    DesignerPropState? state =
        CoreDesigner.propKey.currentState as DesignerPropState?;

    // ignore: invalid_use_of_protected_member
    state?.setState(() {});
  }
}

class MapDesign {
  DesignCtx aCtx;

  MapDesign(this.aCtx);

  void doMap(CoreDataEntity prop) {
    print("set prop on ${aCtx.xid}");
    CoreDesigner.loader.setProp(
        aCtx.xid!, prop
        );

    print('object  ${CoreDesigner.loader.cwFactory}');
  }
}

class LoaderCtx {
  late CoreDataCollection collection;
  WidgetFactoryEventHandler? factory;
  late CoreDataEntity entityCWFactory;
  late ModeRendering mode;
}

class DesignCtx extends LoaderCtx {
  late String pathWidget;
  String? xid;
  CWWidget? widget;

  String? pathDesign;
  String? pathCreate;
}
