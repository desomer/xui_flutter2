import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/data/core_data_loader.dart';
import '../core/data/core_data_query.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import 'cw_factory.dart';
import 'designer_data.dart';
import 'designer_model.dart';

class CWApplication {
  static final CWApplication _current = CWApplication();
  static CWApplication of() {
    return _current;
  }

  CoreDataCollection collection = CoreDataCollection();

  CWWidgetLoaderCtx loaderDesigner = CWWidgetLoaderCtx();
  CWWidgetLoaderCtx loaderModel = CWWidgetLoaderCtx();
  CWWidgetLoaderCtx loaderData = CWWidgetLoaderCtx();

  CWProvider dataModelProvider =
      CWProvider("DataModelProvider", "DataModel", null);
  late CWProvider dataAttributProvider;
  late CWProvider dataProvider;

  Map<String, CoreDataEntity> cacheMapData = {};

  initDesigner() {
    loaderDesigner.collectionWidget = CWWidgetCollectionBuilder().collection;

    loaderDesigner.collectionDataModel = loaderDesigner.collectionWidget;
    loaderDesigner.mode = ModeRendering.design;
    loaderDesigner.entityCWFactory =
        loaderDesigner.collectionWidget.createEntity('CWFactory');
    loaderDesigner.factory = WidgetFactoryEventHandler(loaderDesigner);

    loaderModel.collectionWidget = loaderDesigner.collectionWidget;
    loaderModel.createFactory();

    deleteModel(CWWidgetEvent e) async {
      dataModelProvider.getSelectedEntity()!.operation = CDAction.delete;
      var name = e.provider?.getSelectedEntity()!.value["_id_"];
      CacheResultQuery.saveCache(dataModelProvider);
      dataModelProvider.doEvent(CWProviderAction.onStateDelete, loaderModel,
          repaintXid: "rootModelCol0");
      // supprime les datas
      dataProvider.loader!.deleteAll(name);
    }

    dataModelProvider.addUserAction(
        "delete", CoreDataActionFunction(deleteModel));

    // ajouter l'action de delete
    var c = loaderModel.collectionWidget;
    loaderModel
        .addConstraint('rootAttrExpTitle0', 'CWExpandConstraint')
        .addMany(
            c,
            "actions",
            c.createEntityByJson("CWAction", {
              "_idAction_": "delete@DataModelProvider",
              "label": "Delete table",
              "icon": Icons.delete_forever
            }));

    // custom du loader
    var setProdiverName =
        c.createEntityByJson('CWLoader', {'providerName': "DataModelProvider"});

    loaderModel.setProp("rootAttr", setProdiverName);

    loaderData.collectionWidget = loaderDesigner.collectionWidget;
    loaderData.createFactory();
  }

  initModel() {
    loaderModel.mode = ModeRendering.view;
    loaderModel.collectionDataModel = collection;

    loaderData.mode = ModeRendering.view;
    loaderData.collectionDataModel = collection;

    collection
        .addObject("DataEntity")
        .addAttr("_id_", CDAttributType.CDtext)
        .withAction(AttrActionDefaultUUID())
        .addAttr("_createAt_", CDAttributType.CDdate)
        .addAttr("_updateAt_", CDAttributType.CDdate);

    collection
        .addObject("DataModel")
        .addAttr("name", CDAttributType.CDtext)
        .addAttr("listAttr", CDAttributType.CDmany)
        .addGroup(collection.getClass("DataEntity")!);

    collection.addObject("DataHeader").addAttr("label", CDAttributType.CDtext);

    collection
        .addObject("DataContainer")
        .addAttr("name", CDAttributType.CDtext)
        .addAttr("listData", CDAttributType.CDmany);

    collection
        .addObject("DataAttribut")
        .addAttr("description", CDAttributType.CDtext)
        .addAttr("mask", CDAttributType.CDtext)
        .addAttr("required", CDAttributType.CDbool)
        .addAttr("localized", CDAttributType.CDbool)
        ;

    collection
        .addObject("ModelAttributs")
        .addAttr("_id_", CDAttributType.CDtext)
        .withAction(AttrActionDefaultUUID())
        .addAttr("name", CDAttributType.CDtext)
        .addAttr("type", CDAttributType.CDtext);

    _initProvider();
  }

  Map<String, CoreDataEntity> listModel = {};

  void _initProvider() {
    dataModelProvider.header =
        collection.createEntityByJson("DataHeader", {"label": "Entity"});

    dataModelProvider.addAction(
        CWProviderAction.onStateNone, OnInsertModel(loaderModel));
    dataModelProvider.addAction(
        CWProviderAction.onMapWidget, OnBuildEdit(["name"], false));
    dataModelProvider.addAction(
        CWProviderAction.onRowSelected, OnSelectModel());

    dataModelProvider.loader =
        CoreDataLoaderMap(loaderModel, listModel, "listData")
          ..setMapID("models");

    //----------------------------------------------
    dataAttributProvider = CWProvider("DataAttrProvider", "ModelAttributs",
        CoreDataLoaderNested(loaderModel, dataModelProvider, "listAttr"));

    dataAttributProvider.header =
        collection.createEntityByJson("DataHeader", {"label": "?"});

    dataAttributProvider.addAction(
        CWProviderAction.onMapWidget, OnBuildEdit(["name"], false));
    dataAttributProvider.addAction(
        CWProviderAction.onStateNone, OnAddAttr(dataAttributProvider));
    dataAttributProvider.addAction(
        CWProviderAction.onRowSelected, OnSelectAttribut());        
    //-------------------------------------------------------
    dataProvider = CWProvider("DataProvider", "?",
        CoreDataLoaderMap(loaderData, cacheMapData, "listData"));
    dataProvider.header =
        collection.createEntityByJson("DataHeader", {"label": "?"});

    dataProvider.addAction(
        CWProviderAction.onMapWidget, OnBuildEdit(["*"], true));
    dataProvider.addAction(CWProviderAction.onStateNone, OnInsertData());
    dataProvider.addAction(
        CWProviderAction.onStateNone2Create, SetDate("_createAt_"));
    dataProvider.addAction(
        CWProviderAction.onValueChanged, SetDate("_updateAt_"));
  }
}
