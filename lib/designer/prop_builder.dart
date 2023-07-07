import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_widget.dart';
import 'cw_factory.dart';
import 'designer.dart';
import 'widget_properties.dart';
import 'form_builder.dart';

class PropBuilder {
  List<Widget> listProp = [];

  Map<String, DesignCtx> mapEntityByPath = <String, DesignCtx>{};
  Map<String, CoreDataEntity> mapEntityWidgetByPath =
      <String, CoreDataEntity>{};

  buildWidgetProperties(CWWidgetCtx ctx, int buttonId) {
    String pathWidget = ctx.pathWidget;

    listProp.clear();
    mapEntityByPath.clear();

    while (pathWidget.isNotEmpty) {
      DesignCtx aCtx = DesignCtx();
      aCtx.pathWidget = pathWidget;
      aCtx.xid = ctx.factory.mapXidByPath[pathWidget];
      aCtx.widget = ctx.factory.mapWidgetByXid[aCtx.xid];
      aCtx.pathDesign = aCtx.widget?.ctx.pathDataDesign;
      aCtx.pathCreate = aCtx.widget?.ctx.pathDataCreate;

      mapEntityByPath[pathWidget] = aCtx;

      if (aCtx.widget == null) {
        debugPrint('>>> $pathWidget as empty slot');
        //CoreDesigner.of().controllerTabRight.index = 0;
      } else {
        // if (lastSelection == pathWidget) {
        //   CoreDesigner.of().controllerTabRight.index = 0;
        // }
        // lastSelection = pathWidget;

        aCtx.factory = aCtx.widget!.ctx.factory;
        aCtx.collection = aCtx.widget!.ctx.factory.collection;
        aCtx.mode = ModeRendering.view;
        if (aCtx.widget!.ctx.designEntity == null) {
          var prop = _getEmptyEntity(aCtx);
          var provider = CWProvider(prop);
          provider.addAction(CWProviderAction.onChange, RefreshDesign(aCtx));
          provider.addAction(
              CWProviderAction.onStateCreate, MapDesign(aCtx, prop));
          provider.addAction(
              CWProviderAction.onMountWidget, OnMount(aCtx, pathWidget));

          listProp.addAll(FormBuilder().getFormWidget(provider, aCtx));
        } else {
          var prop = aCtx.widget!.ctx.designEntity!;
          prop.operation = CDAction.read;
          var provider = CWProvider(prop);
          provider.addAction(CWProviderAction.onChange, RefreshDesign(aCtx));
          provider.addAction(
              CWProviderAction.onMountWidget, OnMount(aCtx, pathWidget));

          listProp.addAll(FormBuilder().getFormWidget(provider, aCtx));
        }
      }

      _addSlotConstraint(aCtx, ctx, pathWidget);

      int i = pathWidget.lastIndexOf('.');
      if (i < 0) break;
      pathWidget = pathWidget.substring(0, i);
    }

    DesignerPropState? state =
        CoreDesigner.of().propKey.currentState as DesignerPropState?;

    // ignore: invalid_use_of_protected_member
    state?.setState(() {});
  }

  CoreDataEntity _getEmptyEntity(DesignCtx ctx) {
    ctx.factory = ctx.widget!.ctx.factory;
    CoreDataPath? path = ctx.factory?.cwFactory!
        .getPath(ctx.factory!.collection, ctx.pathCreate!);
    String impl = path!.entities.last.value['implement'];
    CoreDataEntity emptyEntity = ctx.factory!.collection.createEntity(impl);
    return emptyEntity;
  }

  void _addSlotConstraint(
      DesignCtx aCtx, CWWidgetCtx slotCtx, String pathWidget) {
    SlotConfig? sc = slotCtx.factory.mapSlotConstraintByPath[pathWidget];
    if (sc != null && sc.constraintEntity != null) {
      DesignCtx aCtxConstraint = DesignCtx();
      aCtxConstraint.pathWidget = pathWidget;
      debugPrint("SlotConfig ${sc.xid} ${sc.constraintEntity}");
      aCtxConstraint.factory = slotCtx.factory;
      aCtxConstraint.collection = slotCtx.factory.collection;
      aCtxConstraint.mode = ModeRendering.view;
      aCtxConstraint.xid = sc.xid;

      CoreDataEntity constraintEntity =
          slotCtx.factory.mapConstraintByXid[sc.xid]?.designEntity ??
              slotCtx.factory.collection.createEntity(sc.constraintEntity!);

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
