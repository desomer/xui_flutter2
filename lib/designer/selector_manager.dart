import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_widget.dart';
import '../core/widget/cw_factory.dart';
import 'designer.dart';
import 'widget_properties.dart';
import 'form_builder.dart';

class CoreDesignerSelector {
  CoreDesignerSelector() {
    CoreDesigner.on(CDDesignEvent.select, (arg) {
      CWWidgetCtx ctx = arg as CWWidgetCtx;
      showWidgetProperties(ctx, 1);
      unselect();
      select(ctx.pathWidget);
    });

    CoreDesigner.on(CDDesignEvent.reselect, (arg) {
      if (arg == null) {
        SlotConfig? config =
            CoreDesigner.of().factory.mapSlotConstraintByPath[lastSelectedPath];

        if (config != null && config.slot != null) {
          CoreDesigner.emit(
              CDDesignEvent.reselect, config.slot!.key as GlobalKey);
        }
      }
    });
  }

  static final CoreDesignerSelector _current = CoreDesignerSelector();
  static CoreDesignerSelector of() {
    return _current;
  }

  String lastSelection = '';
  List<Widget> listProp = [];
  String lastSelectedPath = '';

  void select(String path) {
    lastSelectedPath = path;
  }

  void unselect() {
    String old = lastSelectedPath;
    lastSelectedPath = "";

    SlotConfig? config = CoreDesigner.of().factory.mapSlotConstraintByPath[old];
    if (config != null) {
      debugPrint("deselection ${config.xid}");
      // Future.delayed(const Duration(milliseconds: 1000), () {
      config.slot?.repaint();
      // });
    }
  }

  doSelectWidgetById(String xid, int buttonId) {
    unselect();
    CWWidget wid = CoreDesigner.of().factory.mapWidgetByXid[xid]!;
    lastSelectedPath = wid.ctx.pathWidget;
    wid.repaint();
    showWidgetProperties(wid.ctx, buttonId);
  }

  showWidgetProperties(CWWidgetCtx ctx, int buttonId) {
    String pathWidget = ctx.pathWidget;

    listProp.clear();

    while (pathWidget.isNotEmpty) {
      DesignCtx aCtx = DesignCtx();
      aCtx.pathWidget = pathWidget;
      aCtx.xid = ctx.factory.mapXidByPath[pathWidget];
      aCtx.widget = ctx.factory.mapWidgetByXid[aCtx.xid];
      aCtx.pathDesign = aCtx.widget?.ctx.pathDataDesign;
      aCtx.pathCreate = aCtx.widget?.ctx.pathDataCreate;

      if (aCtx.widget == null) {
        debugPrint('>>> $pathWidget as empty slot');
        CoreDesigner.of().controllerTabRight.index = 0;
      } else {
        if (lastSelection == pathWidget) {
          CoreDesigner.of().controllerTabRight.index = 0;
        }
        lastSelection = pathWidget;

        aCtx.factory = aCtx.widget!.ctx.factory;
        aCtx.collection = aCtx.widget!.ctx.factory.collection;
        aCtx.mode = ModeRendering.view;
        if (aCtx.widget!.ctx.entityForFactory == null) {
          var prop = _getEmptyEntity(aCtx);
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
      print("SlotConfig ${sc.xid} ${sc.constraintEntity}");
      aCtxConstraint.factory = slotCtx.factory;
      aCtxConstraint.collection = slotCtx.factory.collection;
      aCtxConstraint.mode = ModeRendering.view;
      aCtxConstraint.xid = sc.xid;

      CoreDataEntity constraintEntity =
          slotCtx.factory.mapConstraintByXid[sc.xid]?.entityForFactory ??
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
