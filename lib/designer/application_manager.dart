import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nanoid/nanoid.dart';
import 'package:xui_flutter/designer/designer_model_list.dart';

import '../core/data/core_data.dart';
import '../core/data/core_data_filter.dart';
import '../core/data/core_data_loader.dart';
import '../core/data/core_data_query.dart';
import '../core/data/core_repository.dart';
import '../core/widget/cw_core_bind.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import '../widget/cw_app_router.dart';
import '../widget/cw_expand_panel.dart';
import '../widget/cw_selector.dart';
import '../core/widget/cw_factory.dart';
import 'designer.dart';
import 'designer_model.dart';

class CWApplication {
  static final CWApplication _current = CWApplication();
  static CWApplication of() {
    return _current;
  }

  CoreDataCollection collection = CoreDataCollection();

  CWAppLoaderCtx loaderDesigner = CWAppLoaderCtx(); // pour le design
  CWAppLoaderCtx loaderModel = CWAppLoaderCtx(); // pour les models de data
  CWAppLoaderCtx loaderData = CWAppLoaderCtx(); // pour les data

  CWWidgetCtx? ctxApp;

  // les models
  CWRepository dataModelProvider = CWRepository(
      'DataModelProvider', 'DataModel', CWRepositoryDataSelector.noLoader());

  late CWRepository dataAttributProvider; // les attribut
  late CWRepository dataProvider; // les datas

  CWRepository pagesProvider = CWRepository(
      'PagesProvider', 'PageModel', CWRepositoryDataSelector.noLoader());

  CWRepository listAttrProvider = CWRepository('listAttrProvider',
      'ModelAttributs', CWRepositoryDataSelector.noLoader());

  Map<String, CoreDataEntity> cacheMapData = {};
  Map<String, CoreDataEntity> cacheMapModel = {};
  Map<String, CoreDataFilter> mapFilters = {};

  CWBindWidget bindModel2Filter =
      CWBindWidget('bindModel2Filter', ModeBindWidget.selected);
  CWBindWidget bindModel2Data =
      CWBindWidget('bindModel2Data', ModeBindWidget.selected);
  CWBindWidget bindFilter2Data =
      CWBindWidget('bindFilter2Data', ModeBindWidget.selected);
  CWBindWidget bindModel2Attr =
      CWBindWidget('bindModel2Attr', ModeBindWidget.selected);
  CWBindWidget bindProvider2Attr =
      CWBindWidget('bindProvider2Attr', ModeBindWidget.selected);

  final listRoute = <StatefulShellBranch>[];
  final listAction = <ActionLink>[];
  final listPages = <ActionLink>[];
  ActionLink? currentPage;
  GoRouter? router;

  void goRoute(String route) {
    if (CoreDesigner.of().designView.loader?.ctxLoader.mode ==
        ModeRendering.design) {
      Future.delayed(const Duration(milliseconds: 100), () {
        CWWidget wid =
            CoreDesigner.of().designView.factory.mapWidgetByXid['root']!;
        CoreDesigner.emit(CDDesignEvent.select, wid.ctx);
      });
    }
    for (var p in listPages) {
      if (p.route == route) {
        currentPage = p;
        break;
      }
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      // ignore: invalid_use_of_protected_member
      CoreDesigner.of().pagesKey.currentState?.setState(() {});
    });

    router!.go(route);
  }

  CoreDataEntity? _getEntityPage(CoreDataEntity aNode, String id) {
    if (aNode.value['_id_'] == id) {
      return aNode;
    } else {
      var listSubPage = aNode.getManyEntity(collection, 'subPages') ?? [];

      for (var aSubPage in listSubPage) {
        var ret = _getEntityPage(aSubPage, id);
        if (ret != null) return ret;
      }
    }
    return null;
  }

  CoreDataEntity? getEntityPage(String id) {
    return _getEntityPage(pagesProvider.getEntityByIdx(0), id);
  }

  void _initPage(CoreDataEntity aNode) {
    listPages.add(ActionLink(aNode.value['_id_'], aNode.value['name'],
        aNode.value['route'], ctxApp!));

    var listSubPage = aNode.getManyEntity(collection, 'subPages') ?? [];

    for (var aSubPage in listSubPage) {
      _initPage(aSubPage);
    }
  }

  void initRoutePage() {
    listPages.clear();
    _initPage(pagesProvider.getEntityByIdx(0));
  }

  void clearAllPage() {
    pagesProvider.clearContent();
    pagesProvider.addContent(collection.createEntityByJson(
        'PageModel', {'_id_': 'home', 'route': '/', 'name': 'Home'}));
  }

  void initWidgetLoader() {
    loaderDesigner.modeDesktop = false;

    loaderDesigner.collectionWidget = CWWidgetCollectionBuilder().collection;

    loaderDesigner.entityCWFactory =
        loaderDesigner.collectionWidget.createEntity('CWFactory');
    loaderDesigner.factory = WidgetFactoryEventHandler(loaderDesigner);
    loaderDesigner.setModeRendering(ModeRendering.design);

    loaderModel.collectionWidget = loaderDesigner.collectionWidget;
    loaderModel.createFactory();

    // ajouter l'action de delete table
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
    var propAttr =
        c.createEntityByJson('CWLoader', {iDProviderName: 'DataModelProvider'});
    loaderModel.setProp('rootAttr', propAttr, null);

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
        .addObject('PageModel')
        .addAttr('name', CDAttributType.text)
        .addAttr('route', CDAttributType.text)
        .addAttr('_id_', CDAttributType.text)
        .withAction(AttrActionDefaultUUID())
        .addAttr('subPages', CDAttributType.many);

    ///////////////////////////////////////////////////////////
    collection
        .addObject('DataProvider')
        .addAttr('name', CDAttributType.text)
        .addAttr('type', CDAttributType.text)
        .addAttr('tableModel', CDAttributType.text)
        .addAttr('idProvider', CDAttributType.text);

    ///////////////////////////////////////////////////////////
    collection
        .addObject('StyleModel')
        .addAttr('boxAlignVertical', CDAttributType.text)
        .addAttr('boxAlignHorizontal', CDAttributType.text)
        .addAttr('ptop', CDAttributType.dec)
        .addAttr('pbottom', CDAttributType.dec)
        .addAttr('pleft', CDAttributType.dec)
        .addAttr('pright', CDAttributType.dec)
        .addAttr('elevation', CDAttributType.dec)
        .addAttr('bRadius', CDAttributType.dec)
        .addAttr('bSize', CDAttributType.dec)
        .addAttr('bgColor', CDAttributType.one,
            tname: CWSelectorType.color.name)
        .addAttr('bColor', CDAttributType.one, tname: CWSelectorType.color.name)
        .addAttr('tColor', CDAttributType.one, tname: CWSelectorType.color.name)
        .addAttr('mtop', CDAttributType.dec)
        .addAttr('mbottom', CDAttributType.dec)
        .addAttr('mleft', CDAttributType.dec)
        .addAttr('mright', CDAttributType.dec);

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
        .addAttr('typeCol', CDAttributType.text)
        .addAttr('operator', CDAttributType.text)
        .addAttr('value1', CDAttributType.dynamic)
        .addAttr('value2', CDAttributType.dynamic);

    _initProvider();
  }

  void _initProvider() {
    Future deleteModel(CWWidgetEvent e) async {
      var selectedEntity = dataModelProvider.getSelectedEntity();
      selectedEntity!.operation = CDAction.delete;
      await CoreGlobalCache.saveCache(dataModelProvider);
      dataModelProvider.doEvent(CWRepositoryAction.onStateDelete, loaderModel,
          repaintXid: 'rootModelCol0');
      // supprime les datas
      CoreDataLoaderMap dataLoader = dataProvider.loader as CoreDataLoaderMap;
      // dataLoader.setCacheViewID('AllData_${selectedEntity.value['_id_']}',
      //     onTable: selectedEntity.value['_id_']); // choix de la map a afficher
      dataLoader.deleteAll();
    }

    dataModelProvider.addUserAction(
        'delete', CoreDataActionFunction(deleteModel));

    dataModelProvider.header =
        collection.createEntityByJson('DataHeader', {'label': 'Entity'});

    // dataModelProvider.addAction(
    //     CWRepositoryAction.onStateNone, OnInsertModel(loaderModel));
    dataModelProvider.addAction(
        CWRepositoryAction.onMapWidget, OnBuildEdit(['name'], false));
    dataModelProvider.addAction(
        CWRepositoryAction.onRowSelected, OnSelectModel());

    dataModelProvider.getData().dataloader =
        CoreDataLoaderMap(loaderModel, cacheMapModel, 'listData');

    dataModelProvider.setLoaderTable('models', model: 'DataModel');

    loaderModel.addRepository(dataModelProvider, isEntity: true);
    //----------------------------------------------
    // loader de type nested
    dataAttributProvider = CWRepository(
        'DataAttrProvider',
        'ModelAttributs',
        CWRepositoryDataSelector.loader(
            CoreDataLoaderNested(loaderModel, dataModelProvider, 'listAttr')));

    dataAttributProvider.header =
        collection.createEntityByJson('DataHeader', {'label': '?'});

    dataAttributProvider.addAction(
        CWRepositoryAction.onMapWidget, OnBuildEdit(['name'], false));
    dataAttributProvider.addAction(
        CWRepositoryAction.onStateNone, OnAddAttr(dataAttributProvider));
    dataAttributProvider.addAction(
        CWRepositoryAction.onRowSelected, OnSelectAttribut());

    //-------------------------------------------------------
    listAttrProvider.header =
        collection.createEntityByJson('DataHeader', {'label': '?'});
    listAttrProvider.addAction(
        CWRepositoryAction.onMapWidget, OnIsVisible(['*'], false));

    //-------------------------------------------------------
    dataProvider = CWRepository(
        'DataProvider',
        '?',
        CWRepositoryDataSelector.loader(
            CoreDataLoaderMap(loaderData, cacheMapData, 'listData')));
    dataProvider.header =
        collection.createEntityByJson('DataHeader', {'label': '?'});

    dataProvider.addAction(
        CWRepositoryAction.onMapWidget, OnBuildEdit(['*'], true));

    //----------------------------------------------------------------
    loaderModel.addRepository(pagesProvider, isEntity: false);
    clearAllPage();
  }

  //////////////////////////////////////////////////////////////////////////

  CWRepository getRepositoryFromQuery(CoreDataEntity query, CWWidget widget) {
    CWRepository provider;
    switch (query.type) {
      case 'DataProvider':
        provider = loaderDesigner.getProvider(query.value['idProvider'])!;
        break;
      case 'DataFilter':
        var aFilter = CoreDataFilter()..setFilterData(query);
        provider = CWRepositoryCtx.createFromTable(
            query.value['model'], widget.ctx,
            filter: aFilter);
        break;
      case 'DataModel':
      default:
        provider =
            CWRepositoryCtx.createFromTable(query.value['_id_'], widget.ctx);
    }
    return provider;
  }

  CoreDataEntity getTableEntityByID(String table) {
    List<CoreDataEntity> listTableEntity = dataModelProvider.content;
    var tableEntity = listTableEntity
        .firstWhere((CoreDataEntity element) => element.value['_id_'] == table);
    return tableEntity;
  }

  List<CoreDataAttribut> getTableAllAttrByID(String table) {
    CoreDataObjectBuilder? data =
        loaderModel.collectionDataModel.getClass(table);
    return data!.getAllAttribut();
  }

  CoreDataEntity? getAttributById(String table, String id) {
    var v = getAttributValueById(getTableEntityByID(table), id);
    if (v != null) {
      var ent = collection.createEntity(v[r'$type']);
      ent.value = v;
      return ent;
    } else {
      return null;
    }
  }

  CoreDataAttribut? getAttrById(String table, String attrName) {
    var builder = loaderModel.collectionDataModel.getClass(table);
    return builder?.getAttrById(attrName);
  }

  CoreDataEntity? getCurrentAttributById(String id) {
    var v = getAttributValueById(dataModelProvider.getSelectedEntity()!, id);
    if (v != null) {
      var ent = collection.createEntity(v[r'$type']);
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
      CDAttributType type = CDAttributType.text;
      switch (element['type']) {
        case 'INT':
        case 'INTEGER':
          type = CDAttributType.int;
          break;
        case 'DEC':
        case 'DOUBLE':
          type = CDAttributType.dec;
          break;
        case 'DATE':
          type = CDAttributType.date;
          break;
      }

      data.addAttribut(element['_id_'], type);
    }
    data.addGroup(loader.collectionDataModel.getClass('DataEntity')!);
  }

  CWRepository getDataProvider(
      CWAppLoaderCtx loader, CoreDataEntity tableEntity) {
    var label = tableEntity.value['name'];
    var idData = tableEntity.value['_id_'];

    dataProvider.setLoaderTable(idData);
    //dataProvider.type = idData;
    // CoreDataLoaderMap dataLoader = dataProvider.loader as CoreDataLoaderMap;
    // dataLoader.setCacheViewID(dataProvider,
    //     onTable: idData); // choix de la map a afficher
    dataProvider.header!.value['label'] = label;

    dataProvider.getData().idxSelected = 0;
    return dataProvider;
  }

  CWRepository getDesignDataRepository(
      CWAppLoaderCtx loader, CoreDataEntity tableEntity, String? idProvider,
      {CoreDataFilter? filter}) {
    //var label = tableEntity.value["name"];
    var type = tableEntity.value['_id_'];

    var coreDataLoaderMap = CoreDataLoaderMap(loader, cacheMapData, 'listData');
    CWRepositoryData dataLoaderFinal = CWRepositoryData(coreDataLoaderMap);

    //pas de data en design
    CWRepositoryData dataLoaderDesign = CWRepositoryData(null);

    String id = idProvider ??
        customAlphabet('1234567890abcdef', 10); //tableEntity.value['name'];

    CWRepository designData = CWRepository(id, type,
        CWRepositoryDataSelector(dataLoaderFinal, dataLoaderDesign, loader));

    var aFilter = (filter?.isFilter() ?? false) ? filter : null;
    //var providerCacheID = designData.getRepositoryCacheID(aFilter: aFilter);
    designData.setLoaderTable(type);
    designData.setFilter(aFilter);
    // coreDataLoaderMap.setCacheViewID(designData, onTable: type);

    designData.type = type;
    // une ligne par défaut
    designData.content.add(loader.collectionDataModel.createEntity(type));
    designData.getData().idxSelected = 0;
    return designData;
  }

  void refreshData() {
    CWRepository provider = CWApplication.of().dataProvider;

    provider.initFilter();
    String idCache = provider.getRepositoryCacheID();
    CoreGlobalCache.cacheNbData.remove(idCache);
    provider.loader!.reload();

    CWApplication.of().loaderData.findWidgetByXid('rootData')?.repaint();
  }
}
