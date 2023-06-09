import 'package:flutter/material.dart';

import '../data/core_data.dart';
import '../../designer/cw_factory.dart';
import 'cw_core_widget.dart';


abstract class CWLoader {
  CWLoader(LoaderCtx ctx) {
    ctxLoader = ctx;
    cwFactory = ctx.collectionWidget.createEntity('CWFactory');
    ctxLoader.factory =
        WidgetFactoryEventHandler(ctx.collectionWidget, ctx.mode, ctx);
    ctxLoader.entityCWFactory = cwFactory;
    collection = ctx.collectionWidget;
  }

  late LoaderCtx ctxLoader;
  late CoreDataEntity cwFactory;
  late CoreDataCollection collection;

  setRoot(String implement) {
    cwFactory.setOne(
        collection,
        'child',
        collection.createEntityByJson('CWChild',
            <String, dynamic>{'xid': 'root', 'implement': implement}));
  }

  String setProp(String xid, CoreDataEntity prop) {
    cwFactory.addMany(
        collection,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(collection, 'xid', xid)
            .setOne(collection, 'properties', prop));
    return "designs[${(cwFactory.value["designs"] as List).length - 1}].properties";
  }

  String setConstraint(String xid, CoreDataEntity prop) {
    cwFactory.addMany(
        collection,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(collection, 'xid', xid)
            .setOne(collection, 'constraint', prop));
    return "designs[${(cwFactory.value["designs"] as List).length - 1}].constraint";
  }

  String addChildProp(
      String xid, String xidChild, String implement, CoreDataEntity prop) {
    String ret = addChild(xid, xidChild, implement);
    setProp(xidChild, prop);
    return ret;
  }

  String addChild(String xid, String xidChild, String implement) {
    cwFactory.addMany(
        collection,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(collection, 'xid', xid)
            .setOne(
                collection,
                'child',
                collection.createEntityByJson('CWChild', <String, dynamic>{
                  'xid': xidChild,
                  'implement': implement
                })));

    return "designs[${(cwFactory.value["designs"] as List).length - 1}].child";
  }

  String addWidget(
      String xid, String xidChild, Type type, Map<String, dynamic> v) {
    return addChildProp(xid, xidChild, type.toString(),
        collection.createEntityByJson(type.toString(), v));
  }

  Widget getWidget() {
    final CoreDataEntity aCWFactory = getCWFactory();
    final CoreDataCtx ctx = CoreDataCtx();

    ctx.browseHandler = ctxLoader.factory!;
    ctxLoader.factory!.cwFactory = aCWFactory;
    aCWFactory.browse(collection, ctx);

    final rootWidget = ctxLoader.factory!.mapWidgetByXid['root']!;
    ctxLoader.factory!.mapXidByPath['root'] = 'root';
    rootWidget.initSlot('root');

    return rootWidget;
  }

  CoreDataEntity getCWFactory();
}

class LoaderCtx {
  late CoreDataCollection collectionWidget;
  late CoreDataCollection collectionAppli;
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
  bool isSlot = false;
  CoreDataEntity? designEntity;

  DesignCtx ofWidgetPath(CWWidgetCtx ctx, String path) {
    pathWidget = path;
    xid = ctx.factory.mapXidByPath[path];
    widget = ctx.factory.mapWidgetByXid[xid];
    if (widget != null) {
      pathDesign = widget?.ctx.pathDataDesign;
      pathCreate = widget?.ctx.pathDataCreate;
      designEntity = widget!.ctx.designEntity;
    } else {
      isSlot = true;
    }
    mode = ModeRendering.view;
    this.factory = ctx.factory;
    collectionWidget = ctx.factory.collection;
    return this;
  }

  DesignCtx forDesign(CWWidgetCtx ctx) {
    pathWidget = ctx.pathWidget;
    var isNotSlot = ctx.designEntity != null &&
        ctx.designEntity != ctx.inSlot?.ctx.designEntity;

    if (isNotSlot) {
      xid = ctx.factory.mapXidByPath[pathWidget];
      widget = ctx.factory.mapWidgetByXid[xid];
      pathDesign = widget?.ctx.pathDataDesign;
      pathCreate = widget?.ctx.pathDataCreate;
    } else {
      xid = ctx.inSlot!.ctx.xid;
      widget = ctx.inSlot!;
      isSlot = true;
    }

    if (widget != null) {
      designEntity = widget!.ctx.designEntity;
    }
    mode = ModeRendering.view;
    this.factory = ctx.factory;
    collectionWidget = ctx.factory.collection;

    return this;
  }
}
