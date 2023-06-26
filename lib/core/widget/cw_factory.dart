import 'package:flutter/material.dart';
import 'package:xui_flutter/widget/cw_switch.dart';
import 'package:xui_flutter/widget/cw_text.dart';
import 'package:xui_flutter/widget/cw_textfield.dart';

import '../../widget/cw_container.dart';
import '../../widget/cw_expand_panel.dart';
import '../data/core_data.dart';
import '../data/core_event.dart';
import '../../widget/cw_frame_desktop.dart';
import '../../widget/cw_tab.dart';
import '../data/core_provider.dart';
import 'cw_core_widget.dart';

class CWCollection {
  CWCollection() {
    _initCollection();
    _initWidget();
  }

  final CoreDataCollection collection = CoreDataCollection();

  /////////////////////////////////////////////////////////////////////////
  void _initWidget() {
    addWidget((CWFrameDesktop),
            (CWWidgetCtx ctx) => CWFrameDesktop(key: GlobalKey(), ctx: ctx))
        .addAttr('title', CDAttributType.CDtext);

    addWidget((CWTab), (CWWidgetCtx ctx) => CWTab(key: GlobalKey(), ctx: ctx))
        .addAttr('tabCount', CDAttributType.CDint)
        .addAttr('heightTabBar', CDAttributType.CDint);

    addWidget((CWTextfield),
            (CWWidgetCtx ctx) => CWTextfield(key: GlobalKey(), ctx: ctx))
        .addAttr('label', CDAttributType.CDtext)
        .addAttr('bind', CDAttributType.CDtext)
        .addAttr('providerName', CDAttributType.CDtext);

    addWidget((CWSwitch),
            (CWWidgetCtx ctx) => CWSwitch(key: GlobalKey(), ctx: ctx))
        .addAttr('label', CDAttributType.CDtext)
        .addAttr('bind', CDAttributType.CDtext)
        .addAttr('providerName', CDAttributType.CDtext);

    addWidget((CWExpandPanel),
            (CWWidgetCtx ctx) => CWExpandPanel(key: GlobalKey(), ctx: ctx))
        .addAttr('count', CDAttributType.CDint);

    addWidget((CWText), (CWWidgetCtx ctx) => CWText(key: GlobalKey(), ctx: ctx))
        .addAttr('label', CDAttributType.CDtext)
        .addAttr('textColor', CDAttributType.CDtext);

    addWidget((CWColumn),
            (CWWidgetCtx ctx) => CWColumn(key: GlobalKey(), ctx: ctx))
        .addAttr('count', CDAttributType.CDint)
        .addAttr('fillHeight', CDAttributType.CDbool);

    addWidget((CWRow), (CWWidgetCtx ctx) => CWRow(key: GlobalKey(), ctx: ctx))
        .addAttr('count', CDAttributType.CDint);
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
        .addAttr('properties', CDAttributType.CDone, tname: 'CWWidget');

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
  WidgetFactoryEventHandler(this.collection, this.modeRendering);

  ModeRendering modeRendering;
  CoreDataCollection collection;
  CoreDataEntity? cwFactory;

  Map<String, CWWidget> mapWidgetByXid = <String, CWWidget>{};
  Map<String, String> mapChildXidByXid = <String, String>{};
  Map<String, String> mapXidByPath = <String, String>{};

  Map<String, CWProvider> mapProvider = <String, CWProvider>{};

  void doRepaintByXid(String? xid) {
    CWWidget? widgetRepaint = mapWidgetByXid[xid];
    // ignore: invalid_use_of_protected_member
    (widgetRepaint?.key as GlobalKey).currentState?.setState(() {});
  }

  void doRepaintByPath(String? path) {
    String? xid = mapXidByPath[path];
    CWWidget? widgetRepaint = mapWidgetByXid[xid];
    // ignore: invalid_use_of_protected_member
    (widgetRepaint?.key as GlobalKey).currentState?.setState(() {});
  }

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
        final CWWidgetCtx ctxW = CWWidgetCtx(xid, this, xid, modeRendering);
        ctx.payload = ctxW;
        final CoreDataObjectBuilder wid = collection.getClass(implement)!;
        final CWWidget r = wid.actions['BuildWidget']!.execute(ctx) as CWWidget;
        mapWidgetByXid[xid] = r;
        r.ctx.pathDataCreate = ctx.getPathData();
        //debugPrint(' $xid >>>>>>>>>>>>>>> ${mapWidgetByXid[xid]!}');
      }
      if (ctx.event!.builder.name == 'CWDesign') {
        final String xid = ctx.event!.entity.getString('xid', def: '')!;
        mapWidgetByXid[xid]?.ctx.pathDataDesign = ctx.getPathData();
        final CoreDataEntity? prop =
            ctx.event!.entity.getOneEntity(collection, 'properties');
        if (prop != null) {
          mapWidgetByXid[xid]?.ctx.entityForFactory = prop;
        }
        final CoreDataEntity? child =
            ctx.event!.entity.getOneEntity(collection, 'child');
        if (child != null) {
          mapChildXidByXid[xid] = child.getString('xid', def: '')!;
          debugPrint('$xid ==== ${mapChildXidByXid[xid]}');
        }
      }
    }
  }
}