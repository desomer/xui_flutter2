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

      addSlotConstraint(aCtx, slot, pathWidget);

      int i = pathWidget.lastIndexOf('.');
      if (i < 0) break;
      pathWidget = pathWidget.substring(0, i);
    }

    DesignerPropState? state =
        CoreDesigner.propKey.currentState as DesignerPropState?;

    // ignore: invalid_use_of_protected_member
    state?.setState(() {});
  }

  void addSlotConstraint(
      DesignCtx aCtx, SelectorWidget slot, String pathWidget) {
    SlotConfig? sc = slot.ctx.factory.mapSlotConstraintByPath[pathWidget];
    if (sc != null && sc.constraintEntity != null) {
      DesignCtx aCtxConstraint = DesignCtx();
      aCtxConstraint.pathWidget = pathWidget;
      print("SlotConfig ${sc.xid} ${sc.constraintEntity}");
      aCtxConstraint.factory = slot.ctx.factory;
      aCtxConstraint.collection = slot.ctx.factory.collection;
      aCtxConstraint.mode = ModeRendering.view;
      aCtxConstraint.xid = sc.xid;

      CoreDataEntity constraintEntity =
          slot.ctx.factory.mapConstraintByXid[sc.xid]?.entityForFactory ??
              slot.ctx.factory.collection.createEntity(sc.constraintEntity!);

      var provider = CWProvider(constraintEntity);
      provider.addAction(CWProviderAction.onChange, RefreshDesignParent(aCtx));
      provider.addAction(CWProviderAction.onStateCreate,
          MapConstraint(aCtxConstraint, constraintEntity));
      listProp.addAll(FormBuilder().getFormWidget(provider, aCtxConstraint));
    }
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
  CoreDataEntity? constraint;
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

class RefreshDesignParent extends CoreDataAction {
  RefreshDesignParent(this.aCtx);
  DesignCtx aCtx;

  @override
  execute(CWWidgetCtx ctx, CWWidgetEvent? event) {
    String pathWidget = aCtx.pathWidget;
    int i = pathWidget.lastIndexOf('.');
    if (i > 0) {
      pathWidget = pathWidget.substring(0, i);
    }

    WidgetFactoryEventHandler factory =
        CoreDesigner.coreDesigner.loader.ctxLoader.factory!;

    String xid = factory.mapXidByPath[pathWidget]!;
    CWWidget widget = factory.mapWidgetByXid[xid]!;
    // ignore: invalid_use_of_protected_member
    (widget.key as GlobalKey).currentState?.setState(() {});
  }
}

class MapDesign extends CoreDataAction {
  DesignCtx aCtx;
  CoreDataEntity prop;

  MapDesign(this.aCtx, this.prop);

  @override
  execute(CWWidgetCtx ctx, CWWidgetEvent? event) {
    debugPrint("set prop on ${aCtx.xid}");

    aCtx.widget?.ctx.entityForFactory = prop;
    CoreDesigner.coreDesigner.loader.setProp(aCtx.xid!, prop);
    debugPrint('object  ${CoreDesigner.coreDesigner.loader.cwFactory}');
  }
}

class MapConstraint extends CoreDataAction {
  DesignCtx aCtx;
  CoreDataEntity prop;

  MapConstraint(this.aCtx, this.prop);

  @override
  execute(CWWidgetCtx ctx, CWWidgetEvent? event) {
    debugPrint("set constraint on ${aCtx.xid}");

    CWWidgetCtx ctxConstraint = CWWidgetCtx(
        aCtx.xid!,
        CoreDesigner.coreDesigner.loader.ctxLoader.factory!,
        "?",
        ModeRendering.design);
    ctxConstraint.entityForFactory = prop;
    CoreDesigner.coreDesigner.loader.ctxLoader.factory!
        .mapConstraintByXid[aCtx.xid!] = ctxConstraint;

    // aCtx.widget?.ctx.entityForFactory = prop;
    ctxConstraint.pathDataDesign =
        CoreDesigner.coreDesigner.loader.setConstraint(aCtx.xid!, prop);
    debugPrint('object  ${CoreDesigner.coreDesigner.loader.cwFactory}');
  }
}
