import 'package:flutter/material.dart';

import '../core_data.dart';
import '../core_event.dart';
import 'cw_frame_desktop.dart';
import 'cw_tab.dart';

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
        .addAction('BuildWidget', (CWWidgetCtx ctx) => CWTab(nb: 2, ctx: ctx))
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

    return handler.mapWidget['root']!;
  }
}

class WidgetFactoryEventHandler extends CoreEventHandler {
  WidgetFactoryEventHandler(this.collection);

  CoreDataCollection collection;
  Map<String, CWWidget> mapWidget = <String, CWWidget>{};
  Map<String, String> mapChild = <String, String>{};

  @override
  void process(CoreDataCtx ctx) {
    // super.process(ctx);

    if (ctx.event!.action.startsWith('browserObjectEnd')) {
      final String id = ctx.getPathId();
      final String idParent = ctx.getParentPathId();
      print(
          'id=<$id> p=<$idParent> t=${ctx.event!.builder.name}  o=${ctx.event!.entity}');

      if (ctx.event!.builder.name == 'CWChild') {
        final String xid = ctx.event!.entity.getString('xid', '');
        final String implement = ctx.event!.entity.getString('implement', '');
        final CWWidgetCtx ctxW = CWWidgetCtx(xid, this, xid, ctx);
        ctx.payload = ctxW;
        final CoreDataObjectBuilder wid = collection.getClass(implement)!;
        final CWWidget r = wid.actions['BuildWidget']!.execute(ctx) as CWWidget;
        mapWidget[xid] = r;
        print(' $xid >>>>>>>>>>>>>>> ${mapWidget[xid]!}');
      }
      if (ctx.event!.builder.name == 'CWDesign') {
        final String xid = ctx.event!.entity.getString('xid', '');
        final CoreDataEntity? prop =
            ctx.event!.entity.getOneEntity(collection, 'properties');
        if (prop != null) {
          mapWidget[xid]?.entity = prop;
        }
        final CoreDataEntity? child =
            ctx.event!.entity.getOneEntity(collection, 'child');
        if (child != null) {
          mapChild[xid] = child.getString('xid', '');
          print('$xid ==== ${mapChild[xid]}');
        }
      }
    }
  }
}

// ignore: must_be_immutable
abstract class CWWidget extends StatefulWidget {
  CWWidget({super.key, required this.ctx});
  CWWidgetCtx ctx;
  CoreDataEntity? entity;
  late String childId;
}

class CWWidgetCtx {
  CWWidgetCtx(this.xid, this.factory, this.path, this.ctxData);
  String xid;
  String path;
  WidgetFactoryEventHandler factory;
  CoreDataCtx ctxData;
}
