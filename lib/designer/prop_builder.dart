import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import 'designer.dart';
import 'widget_properties.dart';
import 'builder/form_builder.dart';

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
      DesignCtx aCtx = DesignCtx().ofWidgetPath(ctx, pathWidget);

      mapEntityByPath[pathWidget] = aCtx;

      if (aCtx.widget == null) {
        debugPrint('>>> $pathWidget as empty slot');
      } else {
        CoreDataEntity? designEntity = aCtx.designEntity;
        if (designEntity?.operation == CDAction.inherit) {
          designEntity?.operation == CDAction.read;
        }

        designEntity ??= PropBuilder.getEmptyEntity(aCtx);

        var provider = CWProvider()..add(designEntity);
        provider.addAction(CWProviderAction.onChange, RefreshDesign(aCtx));
        provider.addAction(
            CWProviderAction.onStateCreate, MapDesign(aCtx, designEntity));
        provider.addAction(
            CWProviderAction.onMountWidget, OnMount(aCtx, pathWidget));

        listProp.addAll(FormBuilder().getFormWidget(provider, aCtx));
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

  void _addSlotConstraint(
      DesignCtx aCtx, CWWidgetCtx slotCtx, String pathWidget) {
    SlotConfig? sc = slotCtx.factory.mapSlotConstraintByPath[pathWidget];
    // hasSlotContraint
    if (sc != null && sc.constraintEntity != null) {
      DesignCtx aCtxConstraint = DesignCtx().forDesign(sc.slot!.ctx);

      CoreDataEntity? constraintEntity = aCtxConstraint.designEntity;
      if (constraintEntity?.operation == CDAction.inherit) {
        constraintEntity?.operation == CDAction.read;
      }

      constraintEntity ??= PropBuilder.getEmptyEntity(aCtxConstraint);

      var provider = CWProvider()..add(constraintEntity);
      provider.addAction(CWProviderAction.onChange, RefreshDesignParent(aCtx));
      provider.addAction(CWProviderAction.onStateCreate,
          MapConstraint(aCtxConstraint, constraintEntity));
      listProp.addAll(FormBuilder().getFormWidget(provider, aCtxConstraint));
    }
  }

  /////////////////////////////////////////////////////////////////////////////

  static CoreDataEntity preparePropChange(DesignCtx aCtx) {
    var prop = aCtx.widget!.ctx.designEntity;
    if (prop == null) {
      prop = getEmptyEntity(aCtx);
      setDesignOn(aCtx, prop);
    } else {
      prop.operation = CDAction.read;
    }
    return prop;
  }

  static CoreDataEntity getEmptyEntity(DesignCtx ctx) {
    CoreDataEntity emptyEntity;
    if (ctx.isSlot) {
      SlotConfig sc = ctx.factory!.mapSlotConstraintByPath[ctx.pathWidget]!;
      emptyEntity = ctx.factory!.collection.createEntity(sc.constraintEntity!);
    } else {
      CoreDataPath? path = ctx.factory?.cwFactory!
          .getPath(ctx.factory!.collection, ctx.pathCreate!);
      String impl = path!.entities.last.value['implement'];
      emptyEntity = ctx.factory!.collection.createEntity(impl);
    }

    return emptyEntity;
  }

  static setDesignOn(DesignCtx aCtx, CoreDataEntity prop) {
    if (aCtx.isSlot) {
      CoreDesigner.ofFactory().mapConstraintByXid[aCtx.xid!] = aCtx.widget!.ctx;
      aCtx.widget?.ctx.designEntity = prop;
      aCtx.widget?.ctx.pathDataDesign =
          CoreDesigner.ofLoader().setConstraint(aCtx.xid!, prop);
    } else {
      aCtx.widget?.ctx.designEntity = prop;
      aCtx.widget?.ctx.pathDataDesign =
          CoreDesigner.ofLoader().setProp(aCtx.xid!, prop);
    }
  }
}

