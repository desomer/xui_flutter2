import 'package:flutter/material.dart';
import 'package:xui_flutter/widget/cw_switch.dart';
import 'package:xui_flutter/widget/cw_text.dart';
import 'package:xui_flutter/widget/cw_textfield.dart';

import '../core/widget/cw_core_loader.dart';
import '../widget/cw_container.dart';
import '../widget/cw_expand_panel.dart';
import '../core/data/core_data.dart';
import '../core/data/core_event.dart';
import '../widget/cw_frame_desktop.dart';
import '../widget/cw_list.dart';
import '../widget/cw_tab.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_widget.dart';

class CWCollection {
  CWCollection() {
    _initCollection();
    _initWidget();
  }

  final CoreDataCollection collection = CoreDataCollection();

  /////////////////////////////////////////////////////////////////////////
  void _initWidget() {
    addWidget(
            (CWFrameDesktop),
            (CWWidgetCtx ctx) =>
                CWFrameDesktop(key: GlobalKey(debugLabel: ctx.xid), ctx: ctx))
        .addAttr('title', CDAttributType.CDtext)
        .addAttr('fill', CDAttributType.CDbool);

    CWTab.initFactory(this);

    addWidget((CWTextfield),
            (CWWidgetCtx ctx) => CWTextfield(key: ctx.getKey(), ctx: ctx))
        .addAttr('label', CDAttributType.CDtext)
        .addAttr('bind', CDAttributType.CDtext)
        .addAttr('providerName', CDAttributType.CDtext);

    addWidget((CWSwitch),
            (CWWidgetCtx ctx) => CWSwitch(key: ctx.getKey(), ctx: ctx))
        .addAttr('label', CDAttributType.CDtext)
        .addAttr('bind', CDAttributType.CDtext)
        .addAttr('providerName', CDAttributType.CDtext);

    addWidget((CWExpandPanel),
            (CWWidgetCtx ctx) => CWExpandPanel(key: ctx.getKey(), ctx: ctx))
        .addAttr('count', CDAttributType.CDint);

    CWText.initFactory(this);
    CWColumn.initFactory(this);
    CWRow.initFactory(this);
    CWList.initFactory(this);
  }

  /////////////////////////////////////////////////////////////////////////
  void _initCollection() {
    collection
        .addObject('CWFactory')
        .addAttr('child', CDAttributType.CDone, tname: 'CWChild')
        .addAttr('designs', CDAttributType.CDmany, tname: 'CWDesign');

    collection
        .addObject('CWDesign')
        .addAttr('xid', CDAttributType.CDtext)
        .addAttr('child', CDAttributType.CDone, tname: 'CWChild')
        .addAttr('properties', CDAttributType.CDone, tname: 'CWWidget')
        .addAttr('constraint', CDAttributType.CDone, tname: 'CWWidget');

    collection
        .addObject('CWChild')
        .addAttr('xid', CDAttributType.CDtext)
        .addAttr('implement', CDAttributType.CDtext);
  }

  CoreDataObjectBuilder addWidget(Type t, Function f) {
    return collection.addObject(t.toString()).addObjectAction('BuildWidget', f);
  }
}

class WidgetFactoryEventHandler extends CoreBrowseEventHandler {
  WidgetFactoryEventHandler(this.collection, this.modeRendering, this.loader);

  LoaderCtx loader;
  ModeRendering modeRendering;
  CoreDataCollection collection;
  CoreDataEntity? cwFactory;

  Map<String, CWWidget> mapWidgetByXid = <String, CWWidget>{};
  Map<String, CWWidgetCtx> mapConstraintByXid = <String, CWWidgetCtx>{};
  Map<String, SlotConfig> mapSlotConstraintByPath = <String, SlotConfig>{};

  Map<String, String> mapChildXidByXid = <String, String>{};
  Map<String, String> mapXidByPath = <String, String>{};
  //Map<String, String> mapPathDesignByXid = <String, String>{};

  Map<String, CWProvider> mapProvider = <String, CWProvider>{};

  initSlot() {
    final rootWidget = mapWidgetByXid['root']!;
    rootWidget.initSlot('root');
  }

  // void doRepaintByXid(String? xid) {
  //   CWWidget? widgetRepaint = mapWidgetByXid[xid];
  //   // ignore: invalid_use_of_protected_member
  //   (widgetRepaint?.key as GlobalKey).currentState?.setState(() {});
  // }

  // void doRepaintByPath(String? path) {
  //   String? xid = mapXidByPath[path];
  //   CWWidget? widgetRepaint = mapWidgetByXid[xid];
  //   // ignore: invalid_use_of_protected_member
  //   (widgetRepaint?.key as GlobalKey).currentState?.setState(() {});
  // }

  @override
  void process(CoreDataCtx ctx) {
    // super.process(ctx);

    if (ctx.event!.action.startsWith('browserObjectEnd')) {
      // final String id = ctx.getPathData();
      // final String idParent = ctx.getParentPathData();
      // debugPrint(
      //     'WidgetFactoryEventHandler id=<$id> p=<$idParent> t=${ctx.event!.builder.name}  o=${ctx.event!.entity}');

      if (ctx.event!.builder.name == 'CWChild') {
        final String xid = ctx.event!.entity.getString('xid', def: '')!;
        final String implement =
            ctx.event!.entity.getString('implement', def: '')!;
        final CWWidgetCtx ctxW = CWWidgetCtx(xid, this, xid);
        ctx.payload = ctxW;
        final CoreDataObjectBuilder wid = collection.getClass(implement)!;
        final CWWidget r = wid.actions['BuildWidget']!.execute(ctx) as CWWidget;
        mapWidgetByXid[xid] = r;
        r.ctx.pathDataCreate = ctx.getPathData();
        //debugPrint(' $xid >>>>>>>>>>>>>>> ${mapWidgetByXid[xid]!}');
      }
      if (ctx.event!.builder.name == 'CWDesign') {
        final String xid = ctx.event!.entity.getString('xid', def: '')!;
        String path = ctx.getPathData();
        //mapPathDesignByXid[xid] = path;
        mapWidgetByXid[xid]?.ctx.pathDataDesign = path;

        final CoreDataEntity? prop =
            ctx.event!.entity.getOneEntity(collection, 'properties');
        if (prop != null) {
          mapWidgetByXid[xid]?.ctx.designEntity = prop;
          CWWidgetEvent ctxWE = CWWidgetEvent();
          ctxWE.action = CWProviderAction.onMountWidget.name;
          ctxWE.payload = mapWidgetByXid[xid];

          mapProvider[mapProvider.keys.firstOrNull]
              ?.actions[CWProviderAction.onMountWidget]
              ?.first
              .execute(mapWidgetByXid[xid]!.ctx, ctxWE);
        }

        final CoreDataEntity? constraint =
            ctx.event!.entity.getOneEntity(collection, 'constraint');
        if (constraint != null) {
          CWWidgetCtx ctxConstraint =
              CWWidgetCtx(xid, this, "?");
          ctxConstraint.designEntity = constraint;
          ctxConstraint.pathDataDesign = ctx.getPathData();
          mapConstraintByXid[xid] = ctxConstraint;
        }

        final CoreDataEntity? child =
            ctx.event!.entity.getOneEntity(collection, 'child');
        if (child != null) {
          mapChildXidByXid[xid] = child.getString('xid', def: '')!;
          //debugPrint('$xid ==== ${mapChildXidByXid[xid]}');
        }
      }
    }
  }
}
