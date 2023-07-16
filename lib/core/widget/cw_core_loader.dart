import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_provider.dart';

import '../data/core_data.dart';
import '../../designer/cw_factory.dart';
import 'cw_core_widget.dart';

abstract class CWWidgetLoader {
  CWWidgetLoader(CWWidgetLoaderCtx ctx) {
    ctxLoader = ctx;
  }

  late CWWidgetLoaderCtx ctxLoader;

  CoreDataEntity get cwFactory {
    return ctxLoader.entityCWFactory;
  }

  CoreDataCollection get collection {
    return ctxLoader.collectionWidget;
  }

  CWProvider? getProvider(String name) {
    return ctxLoader.factory.mapProvider[name];
  }

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

    ctx.browseHandler = ctxLoader.factory;
    ctxLoader.entityCWFactory = aCWFactory;
    aCWFactory.browse(collection, ctx);

    final rootWidget = ctxLoader.factory.mapWidgetByXid['root']!;
    ctxLoader.factory.mapXidByPath['root'] = 'root';
    rootWidget.initSlot('root');

    return rootWidget;
  }

  CoreDataEntity getCWFactory();
}

class CWWidgetLoaderCtx {
  late CoreDataCollection collectionWidget;
  late CoreDataCollection collectionAppli;
  late WidgetFactoryEventHandler factory;
  late CoreDataEntity entityCWFactory;
  late ModeRendering mode;

  CWWidgetLoaderCtx from(CWWidgetLoaderCtx ctx) {
    mode = ModeRendering.view;
    collectionWidget = ctx.collectionWidget;
    collectionAppli = ctx.collectionAppli;
    createFactory();
    return this;
  }

  void createFactory() {
    entityCWFactory = collectionWidget.createEntity('CWFactory');
    factory = WidgetFactoryEventHandler(this);
  }

  CWProvider? getProvider(String name) {
    return factory.mapProvider[name];
  }

  CWWidgetCtx? findByXid(String name) {
    return factory.mapWidgetByXid[name]?.ctx;
  }

}

class DesignCtx {
  late String pathWidget;
  String? xid;
  CWWidget? widget;

  String? pathDesign;
  String? pathCreate;
  bool isSlot = false;
  CoreDataEntity? designEntity;

  DesignCtx forDesignByPath(CWWidgetCtx ctx, String path) {
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

    return this;
  }
}
