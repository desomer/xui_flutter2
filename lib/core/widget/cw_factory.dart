import 'package:flutter/material.dart';
import 'package:xui_flutter/widget/cw_text.dart';
import 'package:xui_flutter/widget/cw_textfield.dart';

import '../../widget/cw_container.dart';
import '../../widget/cw_expand_panel.dart';
import '../data/core_data.dart';
import '../data/core_event.dart';
import '../../widget/cw_frame_desktop.dart';
import '../../widget/cw_tab.dart';
import 'cw_core_widget.dart';

class CWCollection {
  CWCollection() {
    _initCollection();
    _initWidget();
  }

  final CoreDataCollection collection = CoreDataCollection();

  /////////////////////////////////////////////////////////////////////////
  void _initWidget() {
    addWidget((CWFrameDesktop), (CWWidgetCtx ctx) => CWFrameDesktop(ctx: ctx))
        .addAttr('title', CDAttributType.CDtext);

    addWidget((CWTab), (CWWidgetCtx ctx) => CWTab(ctx: ctx))
        .addAttr('tabCount', CDAttributType.CDint)
        .addAttr('heightTabBar', CDAttributType.CDint);

    addWidget((CWTextfield), (CWWidgetCtx ctx) => CWTextfield(ctx: ctx))
        .addAttr('label', CDAttributType.CDtext)
        .addAttr('bind', CDAttributType.CDtext)
        .addAttr('providerName', CDAttributType.CDtext);

    addWidget((CWExpandPanel), (CWWidgetCtx ctx) => CWExpandPanel(ctx: ctx))
        .addAttr('count', CDAttributType.CDint);

    addWidget((CWText), (CWWidgetCtx ctx) => CWText(ctx: ctx))
        .addAttr('label', CDAttributType.CDtext)
        .addAttr('textColor', CDAttributType.CDtext);

    addWidget((CWContainer), (CWWidgetCtx ctx) => CWContainer(ctx: ctx))
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

class WidgetFactoryEventHandler extends CoreEventHandler {
  WidgetFactoryEventHandler(this.collection, this.modeRendering);

  ModeRendering modeRendering;
  CoreDataCollection collection;
  CoreDataEntity? root;

  Map<String, CWWidget> mapWidgetByXid = <String, CWWidget>{};
  Map<String, String> mapChildXidByXid = <String, String>{};
  Map<String, String> mapXidByPath = <String, String>{};

  Map<String, CoreDataObjectBuilder> mapProvider =
      <String, CoreDataObjectBuilder>{};

  @override
  void process(CoreDataCtx ctx) {
    // super.process(ctx);

    if (ctx.event!.action.startsWith('browserObjectEnd')) {
      // final String id = ctx.getPathData();
      // final String idParent = ctx.getParentPathData();
      // debugPrint(
      //     'WidgetFactoryEventHandler id=<$id> p=<$idParent> t=${ctx.event!.builder.name}  o=${ctx.event!.entity}');

      if (ctx.event!.builder.name == 'CWChild') {
        final String xid = ctx.event!.entity.getString('xid', '');
        final String implement = ctx.event!.entity.getString('implement', '');
        final CWWidgetCtx ctxW = CWWidgetCtx(xid, this, xid, modeRendering);
        ctx.payload = ctxW;
        final CoreDataObjectBuilder wid = collection.getClass(implement)!;
        final CWWidget r = wid.actions['BuildWidget']!.execute(ctx) as CWWidget;
        mapWidgetByXid[xid] = r;
        r.ctx.pathDataCreate = ctx.getPathData();
        //debugPrint(' $xid >>>>>>>>>>>>>>> ${mapWidgetByXid[xid]!}');
      }
      if (ctx.event!.builder.name == 'CWDesign') {
        final String xid = ctx.event!.entity.getString('xid', '');
        mapWidgetByXid[xid]?.ctx.pathDataDesign = ctx.getPathData();
        final CoreDataEntity? prop =
            ctx.event!.entity.getOneEntity(collection, 'properties');
        if (prop != null) {
          mapWidgetByXid[xid]?.ctx.entity = prop;
        }
        final CoreDataEntity? child =
            ctx.event!.entity.getOneEntity(collection, 'child');
        if (child != null) {
          mapChildXidByXid[xid] = child.getString('xid', '');
          debugPrint('$xid ==== ${mapChildXidByXid[xid]}');
        }
      }
    }
  }
}
