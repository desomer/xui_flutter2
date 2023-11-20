import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/data/core_data_filter.dart';
import '../core/data/core_data_loader.dart';
import '../core/data/core_data_query.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import '../widget/cw_expand_panel.dart';
import 'cw_factory.dart';
import 'designer_model_data.dart';
import 'designer_model.dart';

class CWApplication {
  static final CWApplication _current = CWApplication();
  static CWApplication of() {
    return _current;
  }

  CoreDataCollection collection = CoreDataCollection();

  CWAppLoaderCtx loaderDesigner = CWAppLoaderCtx();
  CWAppLoaderCtx loaderModel = CWAppLoaderCtx();
  CWAppLoaderCtx loaderData = CWAppLoaderCtx();

  CWProvider dataModelProvider = CWProvider(
      'DataModelProvider', 'DataModel', CWProviderDataSelector.noLoader());
  late CWProvider dataAttributProvider;
  late CWProvider dataProvider;

  CWProvider pagesProvider = CWProvider(
      'PagesProvider', 'DataModel', CWProviderDataSelector.noLoader());

  Map<String, CoreDataEntity> cacheMapData = {};
  Map<String, CoreDataEntity> cacheMapModel = {};
  Map<String, CoreDataFilter> mapFilters = {};

  void initDesigner() {
    loaderDesigner.collectionWidget = CWWidgetCollectionBuilder().collection;

    loaderDesigner.entityCWFactory =
        loaderDesigner.collectionWidget.createEntity('CWFactory');
    loaderDesigner.factory = WidgetFactoryEventHandler(loaderDesigner);
    loaderDesigner.setModeRendering(ModeRendering.design);

    loaderModel.collectionWidget = loaderDesigner.collectionWidget;
    loaderModel.createFactory();

    Future deleteModel(CWWidgetEvent e) async {
      var selectedEntity = dataModelProvider.getSelectedEntity();
      selectedEntity!.operation = CDAction.delete;
      await CoreGlobalCache.saveCache(dataModelProvider);
      dataModelProvider.doEvent(CWProviderAction.onStateDelete, loaderModel,
          repaintXid: 'rootModelCol0');
      // supprime les datas
      CoreDataLoaderMap dataLoader = dataProvider.loader as CoreDataLoaderMap;
      dataLoader.setCacheViewID('AllData_${selectedEntity.value['_id_']}',
          onTable: selectedEntity.value['_id_']); // choix de la map a afficher
      dataLoader.deleteAll();
    }

    dataModelProvider.addUserAction(
        'delete', CoreDataActionFunction(deleteModel));

    // ajouter l'action de delete
    var c = loaderModel.collectionWidget;
    loaderModel.collectionDataModel = c;
    loaderModel
        .addConstraint('rootAttrExpTitle0', 'CWExpandConstraint')
        .addMany(
            loaderModel,
            CWExpandAction.actions.toString(),
            c.createEntityByJson('CWExpandAction', {
              '_idAction_': 'delete@DataModelProvider',
              'label': 'Delete table',
              'icon': Icons.delete_forever
            }));

    // custom du loader
    var setProdiverName =
        c.createEntityByJson('CWLoader', {'providerName': 'DataModelProvider'});

    loaderModel.setProp('rootAttr', setProdiverName, null);

    loaderData.collectionWidget = loaderDesigner.collectionWidget;
    loaderData.createFactory();
  }

  void initModel() {
    loaderDesigner.collectionDataModel = collection;

    loaderModel.setModeRendering(ModeRendering.view);
    loaderModel.collectionDataModel = collection;

    loaderData.setModeRendering(ModeRendering.view);
    loaderData.collectionDataModel = collection;

    collection
        .addObject('DataContainer')
        .addAttr('name', CDAttributType.text)
        .addAttr('listData', CDAttributType.many);

    collection // group d'attribut
        .addObject('DataEntity')
        .addAttr('_id_', CDAttributType.text)
        .withAction(AttrActionDefaultUUID())
        .addAttr('_createAt_', CDAttributType.date)
        .addAttr('_updateAt_', CDAttributType.date);

    ///////////////////////////////////////////////////////////
    collection
        .addObject('DataModel')
        .addAttr('name', CDAttributType.text)
        .addAttr('filter', CDAttributType.one)
        .addAttr('listAttr', CDAttributType.many)
        .addGroup(collection.getClass('DataEntity')!);

    collection.addObject('DataHeader').addAttr('label', CDAttributType.text);

    collection // les attributs
        .addObject('ModelAttributs')
        .addAttr('_id_', CDAttributType.text)
        .withAction(AttrActionDefaultUUID())
        .addAttr('name', CDAttributType.text)
        .addAttr('type', CDAttributType.text);

    collection // le formulaire d'attribut
        .addObject('DataAttribut')
        .addAttr('description', CDAttributType.text)
        .addAttr('mask', CDAttributType.text)
        .addAttr('required', CDAttributType.bool)
        .addAttr('localized', CDAttributType.bool);

    ///////////////////////////////////////////////////////////
    collection
        .addObject('DataFilter')
        .addAttr('_id_', CDAttributType.text)
        .withAction(AttrActionDefaultUUID())
        .addAttr('name', CDAttributType.text)
        .addAttr('model', CDAttributType.text)
        .addAttr('listGroup', CDAttributType.many);

    collection
        .addObject('DataFilterGroup')
        .addAttr('operator', CDAttributType.text)
        .addAttr('listClause', CDAttributType.many)
        .addAttr('listGroup', CDAttributType.many);

    collection
        .addObject('DataFilterClause')
        .addAttr('model', CDAttributType.text)
        .addAttr('colId', CDAttributType.text)
        .addAttr('type', CDAttributType.text)
        .addAttr('operator', CDAttributType.text)
        .addAttr('value1', CDAttributType.dynamic)
        .addAttr('value2', CDAttributType.dynamic);

    _initProvider();
  }

  void _initProvider() {
    dataModelProvider.header =
        collection.createEntityByJson('DataHeader', {'label': 'Entity'});

    dataModelProvider.addAction(
        CWProviderAction.onStateNone, OnInsertModel(loaderModel));
    dataModelProvider.addAction(
        CWProviderAction.onMapWidget, OnBuildEdit(['name'], false));
    dataModelProvider.addAction(
        CWProviderAction.onRowSelected, OnSelectModel());

    dataModelProvider.getData().dataloader =
        CoreDataLoaderMap(loaderModel, cacheMapModel, 'listData')
          ..setCacheViewID('models', onTable: 'models');

    loaderModel.addProvider(dataModelProvider);
    //----------------------------------------------
    dataAttributProvider = CWProvider(
        'DataAttrProvider',
        'ModelAttributs',
        CWProviderDataSelector.loader(
            CoreDataLoaderNested(loaderModel, dataModelProvider, 'listAttr')));

    dataAttributProvider.header =
        collection.createEntityByJson('DataHeader', {'label': '?'});

    dataAttributProvider.addAction(
        CWProviderAction.onMapWidget, OnBuildEdit(['name'], false));
    dataAttributProvider.addAction(
        CWProviderAction.onStateNone, OnAddAttr(dataAttributProvider));
    dataAttributProvider.addAction(
        CWProviderAction.onRowSelected, OnSelectAttribut());

    //-------------------------------------------------------
    dataProvider = CWProvider(
        'DataProvider',
        '?',
        CWProviderDataSelector.loader(
            CoreDataLoaderMap(loaderData, cacheMapData, 'listData')));
    dataProvider.header =
        collection.createEntityByJson('DataHeader', {'label': '?'});

    dataProvider.addAction(
        CWProviderAction.onMapWidget, OnBuildEdit(['*'], true));
    dataProvider.addAction(CWProviderAction.onStateNone, OnInsertData());
    dataProvider.addAction(
        CWProviderAction.onStateNone2Create, SetDate('_createAt_'));
    dataProvider.addAction(
        CWProviderAction.onValueChanged, SetDate('_updateAt_'));

    //----------------------------------------------------------------
    loaderModel.addProvider(pagesProvider);
    pagesProvider.addContent(collection
        .createEntityByJson('DataModel', {'_id_': '?', 'name': 'Home'}));
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
    List<dynamic> listAttr = aModelToDisplay.value['listAttr'];

    Map<String, dynamic>? attrDesc;

    for (Map<String, dynamic> attrModel in listAttr) {
      if (attrModel['_id_'] == id) {
        attrDesc = attrModel;
        break;
      }
    }
    return attrDesc;
  }

  void initDataModelWithAttr(
      CWAppLoaderCtx loader, CoreDataEntity tableEntity) {
    var listAttr = tableEntity.value['listAttr'];
    var name = tableEntity.value['_id_'];

    CoreDataObjectBuilder data = loader.collectionDataModel.addObject(name);
    for (var element in listAttr ?? []) {
      data.addAttribut(element['_id_'], CDAttributType.text);
    }
    data.addGroup(loader.collectionDataModel.getClass('DataEntity')!);
  }

  CWProvider getDataProvider(
      CWAppLoaderCtx loader, CoreDataEntity tableEntity) {
    var label = tableEntity.value['name'];
    var idData = tableEntity.value['_id_'];

    dataProvider.type = idData;
    CoreDataLoaderMap dataLoader = dataProvider.loader as CoreDataLoaderMap;
    dataLoader.setCacheViewID(dataProvider.getProviderCacheID(),
        onTable: idData); // choix de la map a afficher
    dataProvider.header!.value['label'] = label;

    dataProvider.getData().idxSelected = 0;
    return dataProvider;
  }

  CWProvider getDesignDataProvider(
      CWAppLoaderCtx loader, CoreDataEntity tableEntity,
      {CoreDataFilter? filter}) {
    //var label = tableEntity.value["name"];
    var type = tableEntity.value['_id_'];

    var coreDataLoaderMap = CoreDataLoaderMap(loader, cacheMapData, 'listData');
    CWProviderData dataLoaderFinal = CWProviderData(coreDataLoaderMap);

    //pas de data en design
    CWProviderData dataLoaderDesign = CWProviderData(null);

    CWProvider designData = CWProvider(tableEntity.value['name'], type,
        CWProviderDataSelector(dataLoaderFinal, dataLoaderDesign, loader));

    var aFilter = (filter?.isFilter() ?? false) ? filter : null;
    var providerCacheID = designData.getProviderCacheID(aFilter: aFilter);
    coreDataLoaderMap.setCacheViewID(providerCacheID, onTable: type);
    designData.setFilter(aFilter);

    designData.type = type;
    // une ligne par défaut
    designData.content.add(loader.collectionDataModel.createEntity(type));
    designData.getData().idxSelected = 0;
    return designData;
  }
}
