import 'package:xui_flutter/core/data/core_repository.dart';

import '../../designer/designer_model_data.dart';
import '../data/core_data.dart';
import 'cw_factory.dart';
import 'cw_core_widget.dart';

abstract class CWWidgetLoader {
  CWWidgetLoader(CWAppLoaderCtx ctx) {
    ctxLoader = ctx;
  }

  late CWAppLoaderCtx ctxLoader;

  CoreDataEntity get cwFactory {
    return ctxLoader.entityCWFactory;
  }

  CoreDataCollection get collection {
    return ctxLoader.collectionWidget;
  }

  CWRepository? getRepository(String name) {
    return ctxLoader.factory.mapRepository[name];
  }

  void setRoot(String xid, String implement) {
    cwFactory.setOne(
        ctxLoader,
        'child',
        collection.createEntityByJson(
            'CWChild', <String, dynamic>{'xid': xid, 'implement': implement}));
  }

  String setProp(String xid, CoreDataEntity prop, {String? path}) {
    return ctxLoader.setProp(xid, prop, path);
  }

  String setConstraint(String xid, CoreDataEntity prop, {String? path}) {
    return ctxLoader.setConstraint(xid, prop, path);
  }

  String addChildProp(
      String xid, String xidChild, String implement, CoreDataEntity prop) {
    String ret = addChild(xid, xidChild, implement);
    setProp(xidChild, prop);
    return ret;
  }

  String addChild(String xid, String xidChild, String implement) {
    cwFactory.addMany(
        ctxLoader,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(ctxLoader, 'xid', xid)
            .setOne(
                ctxLoader,
                'child',
                collection.createEntityByJson('CWChild', <String, dynamic>{
                  'xid': xidChild,
                  'implement': implement
                })));

    return "designs[${(cwFactory.value["designs"] as List).length - 1}].child";
  }

  String addWidget(
      String xid, String xidChild, String type, Map<String, dynamic> v) {
    return addChildProp(
        xid, xidChild, type, collection.createEntityByJson(type, v));
  }

  CWWidget getWidget(String path, String xid) {
    final CoreDataEntity aCWFactory = initCWFactory();
    final CoreDataCtx ctx = CoreDataCtx();

    ctx.browseHandler = ctxLoader.factory;
    ctxLoader.entityCWFactory = aCWFactory;
    aCWFactory.browse(collection, ctx);

    final rootWidget = ctxLoader.factory.mapWidgetByXid[xid]!;
    ctxLoader.factory.mapXidByPath[path] = xid;
    rootWidget.initSlot(path, ModeParseSlot.build);

    return rootWidget;
  }

  CoreDataEntity initCWFactory();
  Future<CoreDataEntity>? loadCWFactory() {
    return null;
  }
}

/////////////////////////////////////////////////////////////////////////////////

class CWAppLoaderCtx {
  late CoreDataCollection collectionWidget;
  late CoreDataCollection collectionDataModel;
  late WidgetFactoryEventHandler factory;
  late CoreDataEntity entityCWFactory;
  late ModeRendering _mode;
  bool modeDesktop = true;

  ModeRendering get mode {
    return _mode;
  }

  void setModeRendering(ModeRendering aMode) {
    _mode = aMode;
  }

  CWAppLoaderCtx from(CWAppLoaderCtx ctx) {
    _mode = ModeRendering.view;
    collectionWidget = ctx.collectionWidget;
    collectionDataModel = ctx.collectionDataModel;
    createFactory();
    return this;
  }

  void createFactory() {
    entityCWFactory = collectionWidget.createEntity('CWFactory');
    factory = WidgetFactoryEventHandler(this);
  }

  CWRepository? getProvider(String name) {
    return factory.mapRepository[name];
  }

  CWWidgetCtx? findByXid(String name) {
    return factory.mapWidgetByXid[name]?.ctx;
  }

  CWWidget? findWidgetByXid(String name) {
    return factory.mapWidgetByXid[name];
  }

  String setProp(String xid, CoreDataEntity prop, String? path) {
    if (path != null) {
      var p = entityCWFactory.getPath(collectionWidget, path);
      p.getLastEntity().value = prop.value;
      return path;
    } else {
      entityCWFactory.addMany(
          this,
          'designs',
          collectionWidget
              .createEntity('CWDesign')
              .setAttr(this, 'xid', xid)
              .setOne(this, 'properties', prop));
      return "designs[${(entityCWFactory.value["designs"] as List).length - 1}].properties";
    }
  }

  String setConstraint(String xid, CoreDataEntity prop, String? path) {
    if (path != null) {
      var p = entityCWFactory.getPath(collectionWidget, path);
      p.getLastEntity().value = prop.value;
      return path;
    } else {
      entityCWFactory.addMany(
          this,
          'designs',
          collectionWidget
              .createEntity('CWDesign')
              .setAttr(this, 'xid', xid)
              .setOne(this, 'constraint', prop));
      return "designs[${(entityCWFactory.value["designs"] as List).length - 1}].constraint";
    }
  }

  CoreDataEntity addConstraint(String xid, String type) {
    var constraint = collectionWidget.createEntity(type);
    setConstraint(xid, constraint, null);
    return constraint;
  }

  void addRepository(CWRepository provider, {required bool isEntity}) {
    if (isEntity && factory.mapRepository[provider.id] != provider) {
      provider.addAction(CWRepositoryAction.onStateNone, OnInsertData());
      provider.addAction(
          CWRepositoryAction.onStateNone2Create, SetDate('_createAt_'));
      provider.addAction(
          CWRepositoryAction.onValueChanged, SetDate('_updateAt_'));
    }

    factory.mapRepository[provider.id] = provider;
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
  CWWidgetCtx? ctxVirtualSlot;

  CWWidgetCtx getCWCtx() {
    return widget?.ctx ?? ctxVirtualSlot!;
  }

  DesignCtx forDesignByPath(CWWidgetCtx ctx, String path, SlotConfig? sc) {
    pathWidget = path;
    xid = ctx.factory.mapXidByPath[path];
    widget = ctx.factory.mapWidgetByXid[xid];
    if (widget != null) {
      pathDesign = widget?.ctx.pathDataDesign;
      pathCreate = widget?.ctx.pathDataCreate;
      designEntity = widget!.ctx.designEntity;
    } else {
      isSlot = true;
      if (sc != null) {
        xid = sc.ctxVirtualSlot!.xid;
        ctxVirtualSlot = sc.ctxVirtualSlot;
        designEntity = ctx.factory.mapConstraintByXid[xid]?.designEntity;
      }
    }

    return this;
  }

  DesignCtx forConstraint(CWWidgetCtx ctx) {
    pathWidget = ctx.pathWidget;
    SlotConfig? sc = ctx.factory.mapSlotConstraintByPath[pathWidget];
    isSlot = true;
    xid = ctx.xid;
    ctxVirtualSlot = sc?.ctxVirtualSlot;
    designEntity = ctx.factory.mapConstraintByXid[xid]?.designEntity;
    return this;
  }

  DesignCtx forDesign(CWWidgetCtx ctx) {
    pathWidget = ctx.pathWidget;
    var isNotSlot = ctx.designEntity != null &&
        ctx.designEntity != ctx.inSlot?.ctx.designEntity;

    if (isNotSlot || ctx.inSlot == null) {
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
