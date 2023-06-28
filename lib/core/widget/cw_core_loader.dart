import 'package:flutter/material.dart';

import '../../designer/selector_manager.dart';
import '../data/core_data.dart';
import 'cw_factory.dart';

abstract class CWLoader {
  CWLoader(LoaderCtx ctx) {
    ctxLoader = ctx;
    cwFactory = ctx.collection.createEntity('CWFactory');
    ctxLoader.factory = WidgetFactoryEventHandler(ctx.collection, ctx.mode);
    ctxLoader.entityCWFactory = cwFactory;
    collection = ctx.collection;
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
    return "designs[${(cwFactory.value["designs"] as List).length-1}].properties";               
  }

  String setConstraint(String xid, CoreDataEntity prop) {
    cwFactory.addMany(
        collection,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(collection, 'xid', xid)
            .setOne(collection, 'constraint', prop));
    return "designs[${(cwFactory.value["designs"] as List).length-1}].constraint";            
  }  

  addChildProp(
      String xid, String xidChild, String implement, CoreDataEntity prop) {
    addChild(xid, xidChild, implement);
    setProp(xidChild, prop);
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

    return "designs[${(cwFactory.value["designs"] as List).length-1}].child";
  }

  addWidget(String xid, String xidChild, Type type, Map<String, dynamic> v) {
    addChildProp(xid, xidChild, type.toString(),
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
