import 'package:flutter/material.dart';

import '../../core/data/core_data.dart';
import '../../core/data/core_repository.dart';
import '../../core/widget/cw_core_loader.dart';
import '../../core/widget/cw_core_widget.dart';
import '../designer.dart';
import '../designer_selector_properties.dart';
import '../help/widget_over_cmp.dart';
import 'form_builder.dart';

class PropBuilder {
  List<Widget> listProp = [];
  List<DesignCtx> listPath = [];
  List<Widget> currentProp = [];

  //Map<String, DesignCtx> mapEntityByPath = <String, DesignCtx>{};
  // Map<String, CoreDataEntity> mapEntityWidgetByPath =
  //     <String, CoreDataEntity>{};

  void buildWidgetProperties(CWWidgetCtx ctx, int buttonId) {
    State? state = CoreDesigner.of().propKey.currentState;
    bool ok = true;

    // ignore: dead_code
    if (ok || state != null) {
      String pathWidget = ctx.pathWidget;

      listProp.clear();
      listPath.clear();

      currentProp.clear();
      while (pathWidget.isNotEmpty) {
        DesignCtx aCtx = DesignCtx().forDesignByPath(ctx, pathWidget, null);

        if (aCtx.widget == null) {
          //debugPrint('>>> $pathWidget as empty slot');
        } else {
          _addWidgetProperties(aCtx, ctx, pathWidget);
          listPath.insert(0, aCtx);
        }

        _addSlotConstraint(aCtx, ctx, pathWidget);
        //_addSlotVirtualConstraint(pathWidget, aCtx, ctx);

        listProp.add(WidgetOverCmp(
            path: pathWidget, child: Column(children: [...currentProp])));
        currentProp.clear();

        // next path
        int i = pathWidget.lastIndexOf('.');
        if (i < 0) break;
        pathWidget = pathWidget.substring(0, i);
        if (pathWidget.endsWith('[]')) {
          i = i - 2;
        }
        pathWidget = pathWidget.substring(0, i);
      }
      listProp.add(WidgetOverCmp(
          path: pathWidget, child: Column(children: [...currentProp])));

      // ignore: invalid_use_of_protected_member
      state?.setState(() {});
    }
  }

  // void _addSlotVirtualConstraint(
  //     String pathWidget, DesignCtx aCtx, CWWidgetCtx ctx) {
  //   int k = pathWidget.lastIndexOf('#');
  //   if (k > 0) {
  //     _addSlotConstraint(aCtx, ctx, pathWidget.substring(0, k));
  //   }
  // }

  void _addWidgetProperties(
      DesignCtx aCtx, CWWidgetCtx ctx, String pathWidget) {
    CoreDataEntity? designEntity = aCtx.designEntity;
    if (designEntity?.operation == CDAction.inherit) {
      designEntity?.operation = CDAction.read;
    }

    designEntity ??= PropBuilder.getEmptyEntity(ctx.loader, aCtx);
    aCtx.designEntity = designEntity;

    // un provider par widget
    var provider = CWRepository('properProvider', designEntity.type,
        CWRepositoryDataSelector.noLoader())
      ..addContent(designEntity);
    provider.addAction(
        CWRepositoryAction.onStateNone2Create, MapDesign(aCtx, designEntity));
    provider.addAction(CWRepositoryAction.onValueChanged, RefreshDesign(aCtx));

    provider.addUserAction('onTapHeader', OnWidgetSelect(aCtx));
    provider.addUserAction('onTapLink', OnBindAction(aCtx, pathWidget));
    provider.addUserAction(
        'showStyle', OnWidgetSelect(aCtx, selectStyle: true));

    CWAppLoaderCtx loader = CWAppLoaderCtx().from(ctx.loader);

    var formWidget =
        FormBuilder().getFormWidget(provider, loader, ModeForm.style);
    currentProp.addAll(formWidget);
  }

  void _addSlotConstraint(
      DesignCtx ctxDesign, CWWidgetCtx slotCtx, String pathWidget) {
    SlotConfig? sc = slotCtx.factory.mapSlotConstraintByPath[pathWidget];
    // hasSlotContraint
    if (sc != null && sc.constraintEntity != null) {
      DesignCtx aCtxConstraint;
      if (sc.slot == null) {
        aCtxConstraint = DesignCtx().forDesignByPath(slotCtx, pathWidget, sc);
      } else {
        aCtxConstraint = DesignCtx().forDesign(sc.slot!.ctx);
      }

      CoreDataEntity? constraintEntity = aCtxConstraint.designEntity;
      if (constraintEntity?.operation == CDAction.inherit) {
        constraintEntity?.operation = CDAction.read;
      }

      constraintEntity ??=
          PropBuilder.getEmptyEntity(slotCtx.loader, aCtxConstraint);

      var provider = CWRepository('constraint', constraintEntity.type,
          CWRepositoryDataSelector.noLoader())
        ..addContent(constraintEntity);

      provider.addAction(
          CWRepositoryAction.onValueChanged, RefreshDesignParent(ctxDesign));
      provider.addAction(CWRepositoryAction.onStateNone2Create,
          MapConstraint(aCtxConstraint, constraintEntity));

      CWAppLoaderCtx loader = CWAppLoaderCtx().from(slotCtx.loader);
      // ajoute les composant du loader
      currentProp.addAll(
          FormBuilder().getFormWidget(provider, loader, ModeForm.expand));
    }

    if (sc != null && sc.pathNested != null) {
      _addSlotConstraint(ctxDesign, slotCtx, sc.pathNested!);
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

    var prop = aCtx.widget?.ctx.designEntity;
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
      var ctx2 = aCtx.getCWCtx();
      ctx2.pathDataDesign = old?.pathDataDesign;
      CoreDesigner.ofFactory().mapConstraintByXid[aCtx.xid!] = ctx2;

      ctx2.designEntity = prop;
      ctx2.pathDataDesign = CoreDesigner.ofLoader()
          .setConstraint(aCtx.xid!, prop, path: ctx2.pathDataDesign);
    } else {
      aCtx.widget?.ctx.designEntity = prop;
      debugPrint(
          'set prop on ${aCtx.xid} path design = ${aCtx.widget?.ctx.pathDataDesign}');
      aCtx.widget?.ctx.pathDataDesign = CoreDesigner.ofLoader()
          .setProp(aCtx.xid!, prop, path: aCtx.widget?.ctx.pathDataDesign);
      debugPrint('set result path design = ${aCtx.widget?.ctx.pathDataDesign}');
    }
  }
}
