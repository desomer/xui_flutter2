import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_widget.dart';
import '../core/widget/cw_factory.dart';
import 'designer.dart';
import 'widget_properties.dart';
import 'form_builder.dart';
import '../core/widget/cw_core_selector.dart';

class CoreDataSelector {
  static String lastSelection = '';
  static List<Widget> listProp = [];

  CoreDataEntity getEmptyEntity(DesignCtx ctx) {
    ctx.factory = ctx.widget!.ctx.factory;
    CoreDataPath? path = ctx.factory?.cwFactory!
        .getPath(ctx.factory!.collection, ctx.pathCreate!);
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
        CoreDesigner.coreDesigner.controllerTabRight.index = 0;
      } else {
        if (lastSelection == pathWidget) {
          CoreDesigner.coreDesigner.controllerTabRight.index = 1;
        }
        lastSelection = pathWidget;

        aCtx.factory = aCtx.widget!.ctx.factory;
        aCtx.collection = aCtx.widget!.ctx.factory.collection;
        aCtx.mode = ModeRendering.view;
        if (aCtx.widget!.ctx.entityForFactory == null) {
          var prop = getEmptyEntity(aCtx);
          var provider = CWProvider(prop);
          provider.addAction(CWProviderAction.onChange, RefreshDesign(aCtx));
          provider.addAction(
              CWProviderAction.onStateCreate, MapDesign(aCtx, prop));
          // prop.custom["onMap"] = MapDesign(aCtx, prop);
          listProp.addAll(FormBuilder().getFormWidget(provider, aCtx));
        } else {
          var prop = aCtx.widget!.ctx.entityForFactory!;
          prop.operation = CDAction.read;
          var provider = CWProvider(prop);
          provider.addAction(CWProviderAction.onChange, RefreshDesign(aCtx));
          listProp.addAll(FormBuilder().getFormWidget(provider, aCtx));
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

////////////////////////////////////////////////////////////
class RefreshDesign extends CoreDataAction {
  RefreshDesign(this.aCtx);
  DesignCtx aCtx;

  @override
  execute(CWWidgetCtx ctx, CWWidgetEvent? event) {
    // ignore: invalid_use_of_protected_member
    (aCtx.widget!.key as GlobalKey).currentState?.setState(() {});
  }
}

class MapDesign extends CoreDataAction {
  DesignCtx aCtx;
  CoreDataEntity prop;

  MapDesign(this.aCtx, this.prop);

  @override
  execute(CWWidgetCtx ctx, CWWidgetEvent? event) {
    print("set prop on ${aCtx.xid}");

    aCtx.widget?.ctx.entityForFactory = prop;
    CoreDesigner.coreDesigner.loader.setProp(aCtx.xid!, prop);
    print('object  ${CoreDesigner.coreDesigner.loader.cwFactory}');
  }
}
