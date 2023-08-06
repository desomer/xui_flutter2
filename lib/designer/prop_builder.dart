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
      DesignCtx aCtx = DesignCtx().forDesignByPath(ctx, pathWidget);

      mapEntityByPath[pathWidget] = aCtx;

      if (aCtx.widget == null) {
        debugPrint('>>> $pathWidget as empty slot');
      } else {
        CoreDataEntity? designEntity = aCtx.designEntity;
        if (designEntity?.operation == CDAction.inherit) {
          designEntity?.operation == CDAction.read;
        }

        designEntity ??= PropBuilder.getEmptyEntity(ctx.loader, aCtx);

        var provider = CWProvider("properties", designEntity.type, null)
          ..add(designEntity);
        provider.addAction(
            CWProviderAction.onValueChanged, RefreshDesign(aCtx));
        provider.addAction(
            CWProviderAction.onStateNone2Create, MapDesign(aCtx, designEntity));
        provider.addAction(
            CWProviderAction.onFactoryMountWidget, OnMount(aCtx, pathWidget));

        CWWidgetLoaderCtx loader = CWWidgetLoaderCtx().from(ctx.loader);
        listProp.addAll(FormBuilder().getFormWidget(provider, loader));
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
      DesignCtx ctxDesign, CWWidgetCtx slotCtx, String pathWidget) {
    SlotConfig? sc = slotCtx.factory.mapSlotConstraintByPath[pathWidget];
    // hasSlotContraint
    if (sc != null && sc.constraintEntity != null) {
      DesignCtx aCtxConstraint = DesignCtx().forDesign(sc.slot!.ctx);

      CoreDataEntity? constraintEntity = aCtxConstraint.designEntity;
      if (constraintEntity?.operation == CDAction.inherit) {
        constraintEntity?.operation == CDAction.read;
      }

      constraintEntity ??=
          PropBuilder.getEmptyEntity(slotCtx.loader, aCtxConstraint);

      var provider = CWProvider("constraint", constraintEntity.type, null)
        ..add(constraintEntity);
      provider.addAction(
          CWProviderAction.onValueChanged, RefreshDesignParent(ctxDesign));
      provider.addAction(CWProviderAction.onStateNone2Create,
          MapConstraint(aCtxConstraint, constraintEntity));

      CWWidgetLoaderCtx loader = CWWidgetLoaderCtx().from(slotCtx.loader);
      listProp.addAll(FormBuilder().getFormWidget(provider, loader));
    }
  }

  /////////////////////////////////////////////////////////////////////////////

  static CoreDataEntity preparePropChange(
      CWWidgetLoaderCtx loader, DesignCtx aCtx) {
    var prop = aCtx.widget!.ctx.designEntity;
    if (prop == null) {
      prop = getEmptyEntity(loader, aCtx);
      setDesignOn(aCtx, prop);
    } else {
      prop.operation = CDAction.read;
    }
    return prop;
  }

  static CoreDataEntity getEmptyEntity(
      CWWidgetLoaderCtx loader, DesignCtx aCtx) {
    CoreDataEntity emptyEntity;
    if (aCtx.isSlot) {
      SlotConfig sc = loader.factory.mapSlotConstraintByPath[aCtx.pathWidget]!;
      emptyEntity = loader.collectionWidget.createEntity(sc.constraintEntity!);
    } else {
      CoreDataPath? path = loader.entityCWFactory
          .getPath(loader.collectionWidget, aCtx.pathCreate!);
      String impl = path.entities.last.value['implement'];
      emptyEntity = loader.collectionWidget.createEntity(impl);
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
