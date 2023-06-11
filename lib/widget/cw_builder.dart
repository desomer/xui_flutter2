import 'package:flutter/material.dart';

import '../core/core_data.dart';
import '../core/core_event.dart';
import 'cw_frame_desktop.dart';
import 'cw_tab.dart';
import 'cw_core_widget.dart';

class CWCollection {
  CoreDataCollection getCollection() {
    final CoreDataCollection collection = CoreDataCollection();

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

  CoreDataEntity getFrame(CoreDataCollection collection) {
    final CoreDataEntity aFrame = collection.createEntity('CWFrame');

    aFrame.setOne(
        collection,
        'child',
        collection.createEntityByJson('CWChild',
            <String, dynamic>{'xid': 'root', 'implement': 'CWFrameDesktop'}));

    final CoreDataEntity aFrameDesktop = collection.createEntityByJson(
        'CWFrame', <String, dynamic>{'title': 'un titre 2'});

    aFrame.addMany(
        collection,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(collection, 'xid', 'root')
            .setOne(collection, 'properties', aFrameDesktop));

    aFrame.addMany(
        collection,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(collection, 'xid', 'rootBody')
            .setOne(
                collection,
                'child',
                collection.createEntityByJson('CWChild',
                    <String, dynamic>{'xid': 'tab1', 'implement': 'CWTab'})));

    final CoreDataEntity aTab = collection.createEntityByJson(
        'CWTab', <String, dynamic>{'nb': 3});

    aFrame.addMany(
        collection,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(collection, 'xid', 'tab1')
            .setOne(
                collection,
                'properties', aTab));

    aFrame.addMany(
        collection,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(collection, 'xid', 'tab1Cont1')
            .setOne(
                collection,
                'child',
                collection.createEntityByJson('CWChild', <String, dynamic>{
                  'xid': 'tabInner',
                  'implement': 'CWTab'
                })));

    return aFrame;
  }

  Widget getWidget() {
    final CoreDataCollection builder = getCollection();
    final CoreDataEntity aFrame = getFrame(builder);
    aFrame.doPrintObject('aFrame');

    final CoreDataCtx ctx = CoreDataCtx();
    final WidgetFactoryEventHandler handler =
        WidgetFactoryEventHandler(builder);

    ctx.eventHandler = handler;
    aFrame.browse(builder, ctx);
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
