import 'package:flutter/material.dart';

import '../../designer/widget_selector.dart';
import '../data/core_data.dart';
import 'cw_factory.dart';

abstract class CWLoader {
  CWLoader(DesignCtx ctx) {
    aFactory = ctx.collection.createEntity('CWFactory');
    handler =
        WidgetFactoryEventHandler(ctx.collection, ctx.mode);
    ctxDesign = ctx;
  }
  late DesignCtx ctxDesign;
  late CoreDataEntity aFactory;
  late WidgetFactoryEventHandler handler;

  setRoot(String implement) {
    aFactory.setOne(
        ctxDesign.collection,
        'child',
        ctxDesign.collection.createEntityByJson('CWChild',
            <String, dynamic>{'xid': 'root', 'implement': implement}));
  }

  setProp(String xid, CoreDataEntity prop) {
    aFactory.addMany(
        ctxDesign.collection,
        'designs',
        ctxDesign.collection.createEntity('CWDesign')
            .setAttr(ctxDesign.collection, 'xid', xid)
            .setOne(ctxDesign.collection, 'properties', prop));
  }

  addChildProp(
      String xid, String xidChild, String implement, CoreDataEntity prop) {
    addChild(xid, xidChild, implement);
    setProp(xidChild, prop);
  }

  addChild(String xid, String xidChild, String implement) {
    aFactory.addMany(
        ctxDesign.collection,
        'designs',
        ctxDesign.collection.createEntity('CWDesign')
            .setAttr(ctxDesign.collection, 'xid', xid)
            .setOne(
                ctxDesign.collection,
                'child',
                ctxDesign.collection.createEntityByJson('CWChild', <String, dynamic>{
                  'xid': xidChild,
                  'implement': implement
                })));
  }

  addWidget(String xid, String xidChild, Type type, Map<String, dynamic> v) {
    addChildProp(xid, xidChild, type.toString(),
        ctxDesign.collection.createEntityByJson(type.toString(), v));
  }

  Widget getWidget(final CoreDataEntity aWidgetEntity) {
    //aWidgetEntity.doPrintObject('aWidgetEntity');

    final CoreDataCtx ctx = CoreDataCtx();

    ctx.eventHandler = handler;
    handler.root = aWidgetEntity;
    aWidgetEntity.browse(ctxDesign.collection, ctx);
    final root = handler.mapWidgetByXid['root']!;
    handler.mapXidByPath['root'] = 'root';
    root.initSlot('root');

    return root;
  }

  CoreDataEntity getWidgetEntity();
}

class CWLoaderTest extends CWLoader {
  CWLoaderTest(super.ctx);

  @override
  CoreDataEntity getWidgetEntity() {
    setRoot('CWFrameDesktop');
    setProp(
        'root',
        ctxDesign.collection.createEntityByJson('CWFrameDesktop',
            <String, dynamic>{'title': 'un titre modifiable'}));

    //------------------------------------------------------------------
    addChildProp(
        'rootBody',
        'tab1',
        'CWTab',
        ctxDesign.collection.createEntityByJson('CWTab', <String, dynamic>{'tabCount': 3}));

    //----------------------------------------------------
    addChildProp(
        'tab1Cont0',
        'aText',
        'CWTextfield',
        ctxDesign.collection.createEntityByJson(
            'CWTextfield', <String, dynamic>{'label': 'un label'}));

    //----------------------------------------------------
    addChild('tab1Cont1', 'tabInner', 'CWTab');

    return aFactory;
  }
}
