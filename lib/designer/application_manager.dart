import 'package:flutter/material.dart';
import 'package:xui_flutter/widget/cw_expand_panel.dart';

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

    loaderDesigner.mode = ModeRendering.design;
    loaderDesigner.entityCWFactory =
        loaderDesigner.collectionWidget.createEntity('CWFactory');
    loaderDesigner.factory = WidgetFactoryEventHandler(loaderDesigner);

    loaderModel.collectionWidget = loaderDesigner.collectionWidget;
    loaderModel.createFactory();

    deleteModel(CWWidgetEvent e) async {
      var selectedEntity = dataModelProvider.getSelectedEntity();
      selectedEntity!.operation = CDAction.delete;
      CoreGlobalCacheResultQuery.saveCache(dataModelProvider);
      dataModelProvider.doEvent(CWProviderAction.onStateDelete, loaderModel,
          repaintXid: "rootModelCol0");
      // supprime les datas
      CoreDataLoaderMap dataLoader = dataProvider.loader as CoreDataLoaderMap;
      dataLoader
          .setMapID(selectedEntity.value["_id_"]); // choix de la map a afficher
      dataLoader.deleteAll();
    }

    dataModelProvider.addUserAction(
        "delete", CoreDataActionFunction(deleteModel));

    // ajouter l'action de delete
    var c = loaderModel.collectionWidget;
    loaderModel.collectionDataModel = c;
    loaderModel
        .addConstraint('rootAttrExpTitle0', 'CWExpandConstraint')
        .addMany(
            loaderModel,
            CWExpandAction.actions.toString(),
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
    loaderDesigner.collectionDataModel = collection;

    loaderModel.mode = ModeRendering.view;
    loaderModel.collectionDataModel = collection;

    loaderData.mode = ModeRendering.view;
    loaderData.collectionDataModel = collection;

    collection
        .addObject("DataContainer")
        .addAttr("name", CDAttributType.CDtext)
        .addAttr("listData", CDAttributType.CDmany);

    collection // group d'attribut
        .addObject("DataEntity")
        .addAttr("_id_", CDAttributType.CDtext)
        .withAction(AttrActionDefaultUUID())
        .addAttr("_createAt_", CDAttributType.CDdate)
        .addAttr("_updateAt_", CDAttributType.CDdate);

    ///////////////////////////////////////////////////////////
    collection
        .addObject("DataModel")
        .addAttr("name", CDAttributType.CDtext)
        .addAttr("filter", CDAttributType.CDone)
        .addAttr("listAttr", CDAttributType.CDmany)
        .addGroup(collection.getClass("DataEntity")!);

    collection.addObject("DataHeader").addAttr("label", CDAttributType.CDtext);

    collection // les attributs
        .addObject("ModelAttributs")
        .addAttr("_id_", CDAttributType.CDtext)
        .withAction(AttrActionDefaultUUID())
        .addAttr("name", CDAttributType.CDtext)
        .addAttr("type", CDAttributType.CDtext);

    collection // le formulaire d'attribut
        .addObject("DataAttribut")
        .addAttr("description", CDAttributType.CDtext)
        .addAttr("mask", CDAttributType.CDtext)
        .addAttr("required", CDAttributType.CDbool)
        .addAttr("localized", CDAttributType.CDbool);

    ///////////////////////////////////////////////////////////
    collection
        .addObject("DataFilter")
        .addAttr("_id_", CDAttributType.CDtext)
        .withAction(AttrActionDefaultUUID())
        .addAttr("name", CDAttributType.CDtext)
        .addAttr("model", CDAttributType.CDtext)
        .addAttr("listGroup", CDAttributType.CDmany);

    collection
        .addObject("DataFilterGroup")
        .addAttr("operator", CDAttributType.CDtext)
        .addAttr("listClause", CDAttributType.CDmany)
        .addAttr("listGroup", CDAttributType.CDmany);

    collection
        .addObject("DataFilterClause")
        .addAttr("model", CDAttributType.CDtext)
        .addAttr("colId", CDAttributType.CDtext)
        .addAttr("type", CDAttributType.CDtext)
        .addAttr("operator", CDAttributType.CDtext)
        .addAttr("value1", CDAttributType.CDdynamic)
        .addAttr("value2", CDAttributType.CDdynamic);

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

    loaderModel.addProvider(dataModelProvider);
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

  //////////////////////////////////////////////////////////////////////////

  CoreDataEntity? getCurrentAttributById(String id) {
    var v = getAttributValueById(
        CWApplication.of().dataModelProvider.getSelectedEntity()!, id);
    if (v != null) {
      var ent = CWApplication.of().collection.createEntity(v[r'$type']);
      ent.value = v;
      return ent;
    } else {
      return null;
    }
  }

  Map<String, dynamic>? getAttributValueById(
      CoreDataEntity aModelToDisplay, String id) {
    List<dynamic> listAttr = aModelToDisplay.value["listAttr"];

    Map<String, dynamic>? attrDesc;

    for (Map<String, dynamic> attrModel in listAttr) {
      if (attrModel["_id_"] == id) {
        attrDesc = attrModel;
        break;
      }
    }
    return attrDesc;
  }

  void initDataModelWithAttr(
      CWWidgetLoaderCtx loader, CoreDataEntity tableEntity) {
    var listAttr = tableEntity.value["listAttr"];
    var name = tableEntity.value["_id_"];

    CoreDataObjectBuilder data = loader.collectionDataModel.addObject(name);
    for (var element in listAttr ?? []) {
      data.addAttribut(element["_id_"], CDAttributType.CDtext);
    }
    data.addGroup(loader.collectionDataModel.getClass("DataEntity")!);
  }

  CWProvider getDataProvider(
      CWWidgetLoaderCtx loader, CoreDataEntity tableEntity) {
    var label = tableEntity.value["name"];
    var idData = tableEntity.value["_id_"];
    CWProvider providerData = CWApplication.of().dataProvider;
    providerData.type = idData;
    CoreDataLoaderMap dataLoader = providerData.loader as CoreDataLoaderMap;
    dataLoader.setMapID(idData); // choix de la map a afficher
    providerData.header!.value["label"] = label;

    providerData.idxSelected = 0;
    return providerData;
  }
}
