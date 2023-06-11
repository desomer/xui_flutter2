import 'package:flutter/material.dart';

import '../data/core_data.dart';
import '../data/core_event.dart';
import '../../widget/cw_frame_desktop.dart';
import '../../widget/cw_tab.dart';
import 'cw_core_widget.dart';

class CWCollection {
  CWCollection() {
    _initCollection();
  }

  final CoreDataCollection collection = CoreDataCollection();

  CoreDataCollection _initCollection() {
    final CoreDataObjectBuilder cwFrame = collection.addObject('CWFrame');
    cwFrame.addAttribut('child', CDAttributType.CDone, tname: 'CWChild');
    cwFrame.addAttribut('designs', CDAttributType.CDmany, tname: 'CWDesign');

    final CoreDataObjectBuilder cwDesign = collection.addObject('CWDesign');
    cwDesign.addAttribut('xid', CDAttributType.CDtext);
    cwDesign.addAttribut('child', CDAttributType.CDone, tname: 'CWChild');
    cwDesign.addAttribut('properties', CDAttributType.CDone, tname: 'CWWidget');

    final CoreDataObjectBuilder cwChild = collection.addObject('CWChild');
    cwChild.addAttribut('xid', CDAttributType.CDtext);
    cwChild.addAttribut('implement', CDAttributType.CDtext);

    //-----------------------------------------------------------------------
    collection
        .addObject('CWFrameDesktop')
        .addAction('BuildWidget', (CWWidgetCtx ctx) => CWFrameDesktop(ctx: ctx))
        .addAttr('title', CDAttributType.CDtext);

    collection
        .addObject('CWTab')
        .addAction('BuildWidget', (CWWidgetCtx ctx) => CWTab(ctx: ctx))
        .addAttr('tabCount', CDAttributType.CDint)
        .addAttr('heightTabBar', CDAttributType.CDint);

    return collection;
  }

  Widget getWidget(final CoreDataEntity aFrame) {
    aFrame.doPrintObject('aFrame');

    final CoreDataCtx ctx = CoreDataCtx();
    final WidgetFactoryEventHandler handler =
        WidgetFactoryEventHandler(collection);

    ctx.eventHandler = handler;
    aFrame.browse(collection, ctx);
    final root = handler.mapWidgetByXid['root']!;
    handler.mapXidByPath['root'] = 'root';
    root.initSlot('root');

    return root;
  }
}

class WidgetFactoryEventHandler extends CoreEventHandler {
  WidgetFactoryEventHandler(this.collection);

  CoreDataCollection collection;
  Map<String, CWWidget> mapWidgetByXid = <String, CWWidget>{};
  Map<String, String> mapChildXidByXid = <String, String>{};
  Map<String, String> mapXidByPath = <String, String>{};

  @override
  void process(CoreDataCtx ctx) {
    // super.process(ctx);

    if (ctx.event!.action.startsWith('browserObjectEnd')) {
      final String id = ctx.getPathData();
      final String idParent = ctx.getParentPathData();
      debugPrint(
          'WidgetFactoryEventHandler id=<$id> p=<$idParent> t=${ctx.event!.builder.name}  o=${ctx.event!.entity}');

      if (ctx.event!.builder.name == 'CWChild') {
        final String xid = ctx.event!.entity.getString('xid', '');
        final String implement = ctx.event!.entity.getString('implement', '');
        final CWWidgetCtx ctxW = CWWidgetCtx(xid, this, xid);
        ctx.payload = ctxW;
        final CoreDataObjectBuilder wid = collection.getClass(implement)!;
        final CWWidget r = wid.actions['BuildWidget']!.execute(ctx) as CWWidget;
        mapWidgetByXid[xid] = r;
        r.ctx.pathDataCreate = ctx.getPathData();
        debugPrint(' $xid >>>>>>>>>>>>>>> ${mapWidgetByXid[xid]!}');
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
