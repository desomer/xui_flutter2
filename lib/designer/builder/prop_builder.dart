import 'package:flutter/material.dart';

import '../../core/data/core_data.dart';
import '../../core/data/core_provider.dart';
import '../../core/widget/cw_core_loader.dart';
import '../../core/widget/cw_core_widget.dart';
import '../designer.dart';
import '../designer_selector_properties.dart';
import 'form_builder.dart';

class PropBuilder {
  List<Widget> listProp = [];

  Map<String, DesignCtx> mapEntityByPath = <String, DesignCtx>{};
  Map<String, CoreDataEntity> mapEntityWidgetByPath =
      <String, CoreDataEntity>{};

  void buildWidgetProperties(CWWidgetCtx ctx, int buttonId) {
    String pathWidget = ctx.pathWidget;

    listProp.clear();
    mapEntityByPath.clear();

    while (pathWidget.isNotEmpty) {
      DesignCtx aCtx = DesignCtx().forDesignByPath(ctx, pathWidget);

      mapEntityByPath[pathWidget] = aCtx;

      if (aCtx.widget == null) {
        //debugPrint('>>> $pathWidget as empty slot');
      } else {
        _addWidgetProp(aCtx, ctx, pathWidget);
      }

      _addSlotConstraint(aCtx, ctx, pathWidget);

      int i = pathWidget.lastIndexOf('.');
      if (i < 0) break;
      pathWidget = pathWidget.substring(0, i);
      if (pathWidget.endsWith('[]')) {
        i = i - 2;
      }
      pathWidget = pathWidget.substring(0, i);
    }

    DesignerPropState? state =
        CoreDesigner.of().propKey.currentState as DesignerPropState?;

    // ignore: invalid_use_of_protected_member
    state?.setState(() {});
  }

  void _addWidgetProp(DesignCtx aCtx, CWWidgetCtx ctx, String pathWidget) {
    CoreDataEntity? designEntity = aCtx.designEntity;
    if (designEntity?.operation == CDAction.inherit) {
      designEntity?.operation = CDAction.read;
    }

    designEntity ??= PropBuilder.getEmptyEntity(ctx.loader, aCtx);

    var provider = CWProvider(
        'properProvider', designEntity.type, CWProviderDataSelector.noLoader())
      ..addContent(designEntity);
    provider.addAction(CWProviderAction.onValueChanged, RefreshDesign(aCtx));
    provider.addAction(
        CWProviderAction.onStateNone2Create, MapDesign(aCtx, designEntity));
    // provider.addAction(
    //     CWProviderAction.onFactoryMountWidget, OnMount(aCtx, pathWidget));
    provider.addUserAction('onTapHeader', OnWidgetSelect(aCtx, pathWidget));
    provider.addUserAction('onTapLink', OnLinkSelect(aCtx, pathWidget));
    

    CWAppLoaderCtx loader = CWAppLoaderCtx().from(ctx.loader);
    provider.header = loader.collectionDataModel.createEntityByJson(
        'DataHeader', {'label': designEntity.type.substring(2)});
    listProp.addAll(FormBuilder().getFormWidget(provider, loader));
  }

  void _addSlotConstraint(
      DesignCtx ctxDesign, CWWidgetCtx slotCtx, String pathWidget) {
    SlotConfig? sc = slotCtx.factory.mapSlotConstraintByPath[pathWidget];
    // hasSlotContraint
    if (sc != null && sc.constraintEntity != null) {
      DesignCtx aCtxConstraint = DesignCtx().forDesign(sc.slot!.ctx);

      CoreDataEntity? constraintEntity = aCtxConstraint.designEntity;
      if (constraintEntity?.operation == CDAction.inherit) {
        constraintEntity?.operation = CDAction.read;
      }

      constraintEntity ??=
          PropBuilder.getEmptyEntity(slotCtx.loader, aCtxConstraint);

      var provider = CWProvider('constraint', constraintEntity.type,
          CWProviderDataSelector.noLoader())
        ..addContent(constraintEntity);

      provider.addAction(
          CWProviderAction.onValueChanged, RefreshDesignParent(ctxDesign));
      provider.addAction(CWProviderAction.onStateNone2Create,
          MapConstraint(aCtxConstraint, constraintEntity));

      CWAppLoaderCtx loader = CWAppLoaderCtx().from(slotCtx.loader);
      listProp.addAll(FormBuilder().getFormWidget(provider, loader));
    }
  }

  /////////////////////////////////////////////////////////////////////////////

  static CoreDataEntity preparePropChange(
      CWAppLoaderCtx loader, DesignCtx aCtx) {
    // TODO : a faire  : exemple height du Tab

    // recherche de la properties Height
    //  soit le slot constraint
    //  soit la height de l'enfant
    //  soit le parent

    var prop = aCtx.widget!.ctx.designEntity;
    if (prop == null) {
      prop = getEmptyEntity(loader, aCtx);
      setDesignOn(aCtx, prop);
    }
    // else {
    //   prop.operation = CDAction.read;
    // }
    return prop;
  }

  static CoreDataEntity getEmptyEntity(CWAppLoaderCtx loader, DesignCtx aCtx) {
    CoreDataEntity? emptyEntity;
    if (aCtx.isSlot) {
      SlotConfig sc = loader.factory.mapSlotConstraintByPath[aCtx.pathWidget]!;
      if (sc.constraintEntity != null) {
        emptyEntity =
            loader.collectionWidget.createEntity(sc.constraintEntity!);
      }
    }
    if (emptyEntity == null) {
      CoreDataPath? path = loader.entityCWFactory
          .getPath(loader.collectionWidget, aCtx.pathCreate!);
      String impl = path.entities.last.value['implement'];
      emptyEntity = loader.collectionWidget.createEntity(impl);
    }

    return emptyEntity;
  }

  static void setDesignOn(DesignCtx aCtx, CoreDataEntity prop) {
    if (aCtx.isSlot) {
      var old = CoreDesigner.ofFactory().mapConstraintByXid[aCtx.xid!];
      aCtx.widget?.ctx.pathDataDesign = old?.pathDataDesign;
      CoreDesigner.ofFactory().mapConstraintByXid[aCtx.xid!] = aCtx.widget!.ctx;

      aCtx.widget?.ctx.designEntity = prop;
      aCtx.widget?.ctx.pathDataDesign = CoreDesigner.ofLoader().setConstraint(
          aCtx.xid!, prop,
          path: aCtx.widget?.ctx.pathDataDesign);
    } else {
      aCtx.widget?.ctx.designEntity = prop;
      aCtx.widget?.ctx.pathDataDesign = CoreDesigner.ofLoader()
          .setProp(aCtx.xid!, prop, path: aCtx.widget?.ctx.pathDataDesign);
    }
  }
}
