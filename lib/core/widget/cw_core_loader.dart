import 'package:flutter/material.dart';

import '../data/core_data.dart';
import 'cw_builder.dart';

abstract class CWLoader {
  CWLoader(this.collection) {
    aFactory = collection.createEntity('CWFactory');
    handler = WidgetFactoryEventHandler(collection);
  }
  CoreDataCollection collection;
  late CoreDataEntity aFactory;
  late WidgetFactoryEventHandler handler;

  setRoot(String implement) {
    aFactory.setOne(
        collection,
        'child',
        collection.createEntityByJson('CWChild',
            <String, dynamic>{'xid': 'root', 'implement': implement}));
  }

  setProp(String xid, CoreDataEntity prop) {
    aFactory.addMany(
        collection,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(collection, 'xid', xid)
            .setOne(collection, 'properties', prop));
  }

  addChild(String xid, String xidChild, String implement) {
    aFactory.addMany(
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
  }

  Widget getWidget(final CoreDataEntity aWidgetEntity) {
    //aWidgetEntity.doPrintObject('aWidgetEntity');

    final CoreDataCtx ctx = CoreDataCtx();

    ctx.eventHandler = handler;
    aWidgetEntity.browse(collection, ctx);
    final root = handler.mapWidgetByXid['root']!;
    handler.mapXidByPath['root'] = 'root';
    root.initSlot('root');

    return root;
  }

  CoreDataEntity getWidgetEntity();
}

class CWLoaderTest extends CWLoader {
  CWLoaderTest(super.collection);

  @override
  CoreDataEntity getWidgetEntity() {
    setRoot('CWFrameDesktop');
    setProp(
        'root',
        collection.createEntityByJson('CWFrameDesktop',
            <String, dynamic>{'title': 'un titre modifiable'}));

    //------------------------------------------------------------------
    addChild('rootBody', 'tab1', 'CWTab');
    setProp('tab1',
        collection.createEntityByJson('CWTab', <String, dynamic>{'tabCount': 3}));

    //----------------------------------------------------
    addChild('tab1Cont0', 'aText', 'CWTextfield');
    setProp(
        'aText',
        collection.createEntityByJson(
            'CWTextfield', <String, dynamic>{'label': 'un label'}));

    //----------------------------------------------------
    addChild('tab1Cont1', 'tabInner', 'CWTab');

    return aFactory;
  }
}
