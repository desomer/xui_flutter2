import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:xui_flutter/core/data/core_data_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/widget/cw_list.dart';

import '../widget/cw_core_widget.dart';
import 'core_data.dart';
import 'core_data_filter.dart';
import 'core_data_query.dart';

enum CWRepositoryAction {
  onFactoryMountWidget, //attribut mount sur un widget avec la prop
  onMapWidget, // permet de renvoyer le type de widget à Mapper
  onStateNone,
  onStateNone2Create,
  onStateDelete,
  onValueChanged,
  onValidateEntity, // l'entity a changer => repaint dependant
  onRowSelected,
  onRefreshEntities, // rafraichit les data (de la base)
  onTapHeader,
}

const String iDProviderName = 'providerName';
const String iDBind = 'bindAttr';

///////////////////////////////////////////////////////////////////////////////////
enum DisplayRenderingMode { selected, displayed }

class CWRepository {
  CWRepository(this.id, this.type, this.dataSelector);

  String id;
  CoreDataEntity? header;
  String type;
  // affiche le display (array) ou le selected (form)
  DisplayRenderingMode displayRenderingMode = DisplayRenderingMode.displayed;

  late CWRepositoryDataSelector dataSelector;

  CoreDataEntity? getEntity() {
    return displayRenderingMode == DisplayRenderingMode.selected
        ? getSelectedEntity()
        : getDisplayedEntity();
  }

  CoreDataEntity getCoreDataEntity() {
    var tableModel = getTableModel();
    String name = '${getQueryName()} (${tableModel.value['name']})';

    var app = CWApplication.of();
    var itemProvider = app.collection.createEntityByJson('DataProvider', {
      'name': name,
      'type': type,
      'tableModel': tableModel,
      'idProvider': id
    });
    return itemProvider;
  }

  String getRepositoryCacheID({CoreDataFilter? aFilter}) {
    if (aFilter != null) {
      return '$id#id=$type;fl=${aFilter.getQueryKey()}';
    }
    if (lockId != null) {
      print('return lock $lockId');
      return lockId!;
    }
    return '$id#id=$type;fl=${getFilter()?.getQueryKey() ?? ''}';
  }

  String getQueryName() {
    var app = CWApplication.of();

    var filter = getFilter();
    if (filter?.isFilter() == true) {
      return 'filter ${filter!.dataFilter.value['name']}';
    } else {
      var tableEntity = app.getTableEntityByID(type);
      return 'all ${tableEntity.value['name']}';
    }
  }

  CoreDataEntity getTableModel() {
    return CWApplication.of().getTableEntityByID(type);
  }

  CWRepositoryData getData() {
    return dataSelector.getData();
  }

  List<CoreDataEntity> get content {
    return dataSelector.getData().content;
  }

  set content(d) {
    dataSelector.getData().content = d;
  }

  CoreDataLoader? get loader {
    return dataSelector.getData().dataloader;
  }

  void initFilter() {
    var filter = getFilter();
    if (filter != null) {
      setFilter(filter);
    }
  }

  void setFilter(CoreDataFilter? aFilter) {
    dataSelector.finalData.dataloader?.setFilter(this, aFilter);

    dataSelector.finalData.dataloader
        ?.setCacheViewID(this); // choix de la map a afficher
  }

  void setLoaderTable(String idTable, {String? model}) {
    type = idTable;
    if (loader is CoreDataLoaderMap) {
      CoreDataLoaderMap dataLoader = loader as CoreDataLoaderMap;
      dataLoader.setCacheViewID(this);
    }
    if (model != null) {
      type = model;
    }
  }

  CoreDataFilter? getFilter() {
    return dataSelector.finalData.dataloader?.getFilter();
  }

  void addContent(CoreDataEntity add) {
    getData().content.add(add);
    if (getData().idxDisplayed == -1) getData().idxDisplayed = 0;
    if (getData().idxSelected == -1) getData().idxSelected = 0;
  }

  void addNew(CoreDataEntity newRow) {
    if (getData().dataloader != null) {
      getData().dataloader?.addData(newRow);
    }
    addContent(newRow);

    CoreGlobalCache.notifNewRow(this);
  }

  void clearContent() {
    getData().content.clear();
    getData().idxDisplayed = -1;
    getData().idxSelected = -1;
  }

  void addAll(CWAppLoaderCtx loaderCtx, List<dynamic>? list) {
    if (list != null) {
      for (Map<String, dynamic> element in list) {
        var ent = loaderCtx.collectionDataModel.createEntity(element[r'$type']);
        ent.value = element;
        addContent(ent);
      }
    }
  }

  CoreDataEntity getEntityByIdx(idx) {
    return getData().content[idx];
  }

  CoreDataEntity? getDisplayedEntity() {
    if (getData().idxDisplayed == -1) {
      getData().idxDisplayed = 0;
      debugPrint('getData().idxDisplayed == -1');
    }
    if (getData().idxDisplayed >= getData().content.length) {
      getData().idxDisplayed = -1;
      return null;
    }
    return getData().content[getData().idxDisplayed];
  }

  CoreDataEntity? getSelectedEntity() {
    if (getData().idxSelected == -1) return null;
    if (getData().idxSelected >= getData().content.length) {
      getData().idxSelected = -1;
      return null;
    }
    return getData().content[getData().idxSelected];
  }

  CoreDataAction addAction(CWRepositoryAction idAction, CoreDataAction action) {
    if (getData().actions[idAction] == null) getData().actions[idAction] = [];
    getData().actions[idAction]!.add(action);
    return action;
  }

  bool removeAction(CWRepositoryAction idAction, CoreDataAction? action) {
    if (action == null || getData().actions[idAction] == null) return false;
    return getData().actions[idAction]!.remove(action);
  }

  CWRepository addUserAction(String idAction, CoreDataAction action) {
    if (getData().userActions[idAction] == null) {
      getData().userActions[idAction] = [];
    }
    getData().userActions[idAction]!.add(action);
    return this;
  }

  CWRepository doAction(
      CWWidgetCtx? ctx, CWWidgetEvent? event, CWRepositoryAction idAction) {
    event?.widgetCtx = ctx;
    if (getData().actions[idAction] != null) {
      for (var act in getData().actions[idAction]!) {
        act.execute(ctx, event);
      }
    }
    return this;
  }

  Future<CWRepository> doUserAction(
      CWWidgetCtx? ctx, CWWidgetEvent? event, String idAction) async {
    event?.widgetCtx = ctx;
    var isNotDesign = ctx!.loader.mode == ModeRendering.view;

    void doOnView(Function f) {
      if (isNotDesign) {
        f();
      }
    }

    switch (idAction) {
      case '<Read':
        doOnView(() => doPrev(event, ctx));
        return this;
      case 'Read>':
        doOnView(() => doNext(event, ctx));
        return this;
      case 'Update':
        doOnView(() async => (await CoreGlobalCache.saveCache(this)));
        return this;
      case 'Refresh':
        doOnView(() {
          CoreGlobalCache.clearCache(ctx.loader, this);
          doEvent(CWRepositoryAction.onRefreshEntities, ctx.loader);
        });
        return this;
      case 'Delete':
        doOnView(() async {
          doDelete(ctx.loader, getData().idxSelected, null);
          await CoreGlobalCache.saveCache(this);
          CoreGlobalCache.clearCache(ctx.loader, this);
          doEvent(CWRepositoryAction.onRefreshEntities, ctx.loader);
        });
        return this;
      case 'Create':
        doOnView(() {
          doCreate(event, ctx);
        });
        return this;
      default:
    }

    if (getData().userActions[idAction] != null) {
      for (var act in getData().userActions[idAction]!) {
        act.execute(ctx, event);
      }
    } else {
      print('doUserAction $idAction inconnu');
    }
    return this;
  }

  void doCreate(CWWidgetEvent? event, CWWidgetCtx ctx) {
    CoreDataEntity newRow =
        ctx.loader.collectionDataModel.createEntityByJson(type, {});

    addNew(newRow);
    doEvent(CWRepositoryAction.onStateNone, ctx.loader);
    var data = getData();
    data.idxSelected = data.getCount() - 1;
    event!.payload = data.idxSelected;
    displayRenderingMode = DisplayRenderingMode.selected;
    doAction(ctx, event, CWRepositoryAction.onRowSelected);
  }

  void doDelete(CWAppLoaderCtx loader, int idx, InheritedRow? row) {
    content[idx].operation = CDAction.delete;
    doEvent(CWRepositoryAction.onStateDelete, loader, row: row);
    doEvent(CWRepositoryAction.onValidateEntity, loader, row: row);
  }

  void doNext(CWWidgetEvent? event, CWWidgetCtx? ctx) {
    var data = getData();
    if (data.idxSelected + 1 < data.getCount()) {
      data.idxSelected++;
      event!.payload = data.idxSelected;
      displayRenderingMode = DisplayRenderingMode.selected;
      doAction(ctx, event, CWRepositoryAction.onRowSelected);
    }
  }

  void doPrev(CWWidgetEvent? event, CWWidgetCtx? ctx) {
    var data = getData();
    if (data.idxSelected > 0) {
      data.idxSelected--;
      event!.payload = data.idxSelected;
      displayRenderingMode = DisplayRenderingMode.selected;
      doAction(ctx, event, CWRepositoryAction.onRowSelected);
    }
  }

  static CWRepository? of(CWWidgetCtx ctx, {String? id}) {
    CWRepository? provider = ctx.factory
        .mapRepository[id ?? ctx.designEntity?.getString(iDProviderName)];
    return provider;
  }

  String? getAttrName(String idAttr) {
    var app = CWApplication.of();
    return app.getAttributValueById(getTableModel(), idAttr)?['name'];
  }

  /////////////////////////////////////////////////////////////////////////
  String getStringValueOf(CWWidgetCtx ctx, String propName) {
    var val = getEntity()?.value[ctx.designEntity?.getString(propName)];
    return val?.toString() ?? '';
  }

  bool getBoolValueOf(CWWidgetCtx ctx, String propName) {
    var val = getEntity()!.value[ctx.designEntity?.getString(propName)];
    return val ?? false;
  }

  double? getDoubleValueOf(CWWidgetCtx ctx, String propName) {
    var val = getEntity()!.value[ctx.designEntity?.getString(propName)];
    return val;
  }

  Map<String, dynamic>? getMapValueOf(CWWidgetCtx ctx, String propName) {
    var val = getEntity()!.value[ctx.designEntity?.getString(propName)];
    return val;
  }

  void setValueOf(
      CWWidgetCtx ctx, CWWidgetEvent? event, String attrName, dynamic val) {
    dynamic v = val;

    var displayedEntity = getEntity();

    CoreDataAttribut? attr =
        displayedEntity!.getAttrByName(ctx.loader, attrName);
    if (attr?.type == CDAttributType.int) {
      v = int.tryParse(val);
    } else if (attr?.type == CDAttributType.dec) {
      v = double.tryParse(val);
    }

    displayedEntity.setAttr(ctx.loader, attrName, v);

    var rowOperation = displayedEntity.operation;
    if (rowOperation == CDAction.none) {
      doAction(ctx, event, CWRepositoryAction.onStateNone2Create);
    }
    doAction(ctx, event, CWRepositoryAction.onValueChanged);

    getData().dataloader?.changed(this, displayedEntity);
  }

  void setValuePropOf(
      CWWidgetCtx ctx, CWWidgetEvent? event, String propName, dynamic val) {
    return setValueOf(ctx, event, ctx.designEntity!.getString(propName)!, val);
  }

  String? lockId;

  Future<int> getItemsCount(CWWidgetCtx ctx) async {
    if (getData().dataloader != null) {
      initFilter();
      var result = await getData().dataloader!.getDataAsync(ctx);
      getData().content = result;
      CoreGlobalCache.setCacheValue(this, getData().content);
    }
    return getData().content.length;
  }

  int getItemsCountSync() {
    if (getData().dataloader != null) {
      var result = getData().dataloader!.getDataSync();
      // debugPrint('set getItemsCountSync ${getData().hashCode} content $result');
      getData().content = result;
    }
    return getData().content.length;
  }

  void doEvent(CWRepositoryAction event, CWAppLoaderCtx loader,
      {InheritedRow? row, String? repaintXid}) {
    CWWidgetEvent ctxWE = CWWidgetEvent();
    ctxWE.action = event.toString();
    ctxWE.provider = this;
    ctxWE.loader = loader;
    ctxWE.payload = row;
    doAction(null, ctxWE, event);
    if (repaintXid != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        loader.factory.mapWidgetByXid[repaintXid]!.repaint();
      });
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
class CWRepositoryData {
  CWRepositoryData(this.dataloader);

  List<CoreDataEntity> content = [];
  int idxDisplayed = -1;
  int idxSelected = -1;
  Map<CWRepositoryAction, List<CoreDataAction>> actions = {};
  Map<String, List<CoreDataAction>> userActions = {};
  CoreDataLoader? dataloader;

  int getCount() {
    return content.length;
  }
}

class CWRepositoryDataSelector {
  CWRepositoryDataSelector(this.finalData, this.designData, this.appLoader);
  CWRepositoryData designData;
  CWRepositoryData finalData;
  CWAppLoaderCtx? appLoader;

  static CWRepositoryDataSelector noLoader() {
    CWRepositoryData data = CWRepositoryData(null);
    return CWRepositoryDataSelector(data, data, null);
  }

  static CWRepositoryDataSelector loader(CoreDataLoader loader) {
    CWRepositoryData data = CWRepositoryData(loader);
    return CWRepositoryDataSelector(data, data, null);
  }

  CWRepositoryData getData() {
    var mode = appLoader?.mode ?? ModeRendering.view;

    switch (mode) {
      case ModeRendering.view:
        return finalData;
      default:
        return designData;
    }
  }
}

//////////////////////////////////////////////////////////////////////////////
final log = Logger('CWProviderCtx');

class CWRepositoryCtx extends CWWidgetVirtual {
  CWRepositoryCtx(super.ctx);

  @override
  void init() {
    var providerName = ctx.designEntity!.value[iDProviderName];
    if (ctx.loader.factory.mapRepository[providerName] == null) {
      CWRepository provider = createFromTable(
          ctx.designEntity!.value['type'], ctx,
          idProvider: providerName);
      provider.id = providerName;
      String filterID = ctx.designEntity!.value['filter'] ?? 'none';
      provider.setFilter(CWApplication.of().mapFilters[filterID]);
      log.fine(
          'init appli provider <${provider.id}> [${provider.type}] hash = ${provider.getData().hashCode}');
      ctx.loader.addRepository(provider, isEntity: true);
    }
  }

  static CWRepository createFromTable(String idModel, CWWidgetCtx ctx,
      {String? idProvider, CoreDataFilter? filter}) {
    var app = CWApplication.of();
    var tableEntity = app.getTableEntityByID(idModel);
    app.initDataModelWithAttr(ctx.loader, tableEntity);
    CWRepository provider = app.getDesignDataRepository(
        ctx.loader, tableEntity, idProvider,
        filter: filter);
    return provider;
  }
}

abstract class CoreDataAction {
  dynamic execute(CWWidgetCtx? ctx, CWWidgetEvent? event);
}

class CoreDataActionFunction extends CoreDataAction {
  CoreDataActionFunction(this.fct);
  Function fct;
  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    fct(event);
  }
}
