import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:xui_flutter/core/data/core_data_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/designer/application_manager.dart';

import '../widget/cw_core_widget.dart';
import 'core_data.dart';
import 'core_data_filter.dart';
import 'core_data_query.dart';

enum CWProviderAction {
  onFactoryMountWidget, //attribut mount sur un widget avec la prop
  onMapWidget, // permet de renvoyer le type de widget à Mapper
  onStateNone,
  onStateNone2Create,
  onStateDelete,
  onValueChanged,
  onRowSelected,
  onTapHeader
}

class CWProviderData {
  CWProviderData(this.dataloader);

  List<CoreDataEntity> content = [];
  int idxDisplayed = -1;
  int idxSelected = -1;
  Map<CWProviderAction, List<CoreDataAction>> actions = {};
  Map<String, List<CoreDataAction>> userActions = {};
  CoreDataLoader? dataloader;
}

class CWProviderDataSelector {
  CWProviderDataSelector(this.finalData, this.designData, this.appLoader);
  CWProviderData designData;
  CWProviderData finalData;
  CWAppLoaderCtx? appLoader;

  static CWProviderDataSelector noLoader() {
    CWProviderData data = CWProviderData(null);
    return CWProviderDataSelector(data, data, null);
  }

  static CWProviderDataSelector loader(CoreDataLoader loader) {
    CWProviderData data = CWProviderData(loader);
    return CWProviderDataSelector(data, data, null);
  }

  CWProviderData getData() {
    var mode = appLoader?.mode ?? ModeRendering.view;

    switch (mode) {
      case ModeRendering.view:
        return finalData;
      default:
        return designData;
    }
  }
}

final log = Logger('CWProviderCtx');

class CWProviderCtx extends CWWidgetVirtual {
  CWProviderCtx(super.ctx);

  @override
  void init() {
    if (ctx.loader.factory
            .mapProvider[ctx.designEntity!.value['providerName']] ==
        null) {
      CWProvider provider =
          createFromTable(ctx.designEntity!.value['type'], ctx);
      log.fine(
          'init appli provider <${provider.name}> [${provider.type}] hash = ${provider.getData().hashCode}');
      ctx.loader.factory.mapProvider[provider.name] = provider;
    }
  }

  static CWProvider createFromTable(String id, CWWidgetCtx ctx) {
    var app = CWApplication.of();
    List<CoreDataEntity> listTableEntity = app.dataModelProvider.content;
    var tableEntity = listTableEntity
        .firstWhere((CoreDataEntity element) => element.value['_id_'] == id);
    app.initDataModelWithAttr(ctx.loader, tableEntity);
    CWProvider provider = app.getDesignDataProvider(ctx.loader, tableEntity);
    return provider;
  }
}

class CWProvider {
  CWProvider(this.name, this.type, this.dataSelector);

  String name;
  CoreDataEntity? header;
  String type;

  late CWProviderDataSelector dataSelector;

  String getProviderCacheID({CoreDataFilter? aFilter}) {
    if (aFilter!=null) {
      return '$name#id=$type;fl=${aFilter.hashCode}';
    }
    return '$name#id=$type;fl=${dataSelector.getData().dataloader?.getFilter()?.hashCode ?? 'null'}';
  }

  CWProviderData getData() {
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

  void setFilter(CoreDataFilter? aFilter) {
    getData().dataloader?.setFilter(this, aFilter);
  }

  void addContent(CoreDataEntity add) {
    getData().content.add(add);
    if (getData().idxDisplayed == -1) getData().idxDisplayed = 0;
  }

  void addNew(CoreDataEntity newRow) {
    if (getData().dataloader != null) {
      getData().dataloader?.addData(newRow);
    }
    addContent(newRow);

    CoreGlobalCache.notifNewRow(this);
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

  CWProvider addAction(CWProviderAction idAction, CoreDataAction action) {
    if (getData().actions[idAction] == null) getData().actions[idAction] = [];
    getData().actions[idAction]!.add(action);
    return this;
  }

  CWProvider addUserAction(String idAction, CoreDataAction action) {
    if (getData().userActions[idAction] == null) {
      getData().userActions[idAction] = [];
    }
    getData().userActions[idAction]!.add(action);
    return this;
  }

  CWProvider doAction(
      CWWidgetCtx? ctx, CWWidgetEvent? event, CWProviderAction idAction) {
    event?.widgetCtx = ctx;
    if (getData().actions[idAction] != null) {
      for (var act in getData().actions[idAction]!) {
        act.execute(ctx, event);
      }
    }
    return this;
  }

  CWProvider doUserAction(
      CWWidgetCtx? ctx, CWWidgetEvent? event, String idAction) {
    event?.widgetCtx = ctx;
    if (getData().userActions[idAction] != null) {
      for (var act in getData().userActions[idAction]!) {
        act.execute(ctx, event);
      }
    }
    return this;
  }

  static CWProvider? of(CWWidgetCtx ctx) {
    CWProvider? provider =
        ctx.factory.mapProvider[ctx.designEntity?.getString('providerName')];
    return provider;
  }

  String getStringValueOf(CWWidgetCtx ctx, String propName) {
    var val =
        getDisplayedEntity()?.value[ctx.designEntity?.getString(propName)];
    return val?.toString() ?? '';
  }

  bool getBoolValueOf(CWWidgetCtx ctx, String propName) {
    var val =
        getDisplayedEntity()!.value[ctx.designEntity?.getString(propName)];
    return val ?? false;
  }

  Map<String, dynamic>? getMapValueOf(CWWidgetCtx ctx, String propName) {
    var val =
        getDisplayedEntity()!.value[ctx.designEntity?.getString(propName)];
    return val;
  }

  void setValueOf(
      CWWidgetCtx ctx, CWWidgetEvent? event, String propName, dynamic val) {
    dynamic v = val;
    CoreDataAttribut? attr = getDisplayedEntity()!
        .getAttrByName(ctx.loader, ctx.designEntity!.getString(propName)!);
    if (attr?.type == CDAttributType.int) {
      v = int.tryParse(val);
    } else if (attr?.type == CDAttributType.dec) {
      v = double.tryParse(val);
    }

    getDisplayedEntity()!
        .setAttr(ctx.loader, ctx.designEntity!.getString(propName)!, v);

    var displayedEntity = getDisplayedEntity();

    var rowOperation = displayedEntity!.operation;
    if (rowOperation == CDAction.none) {
      doAction(ctx, event, CWProviderAction.onStateNone2Create);
    }
    doAction(ctx, event, CWProviderAction.onValueChanged);

    getData().dataloader?.changed(this, displayedEntity);
  }

  Future<int> getItemsCount(CWWidgetCtx ctx) async {
    if (getData().dataloader != null) {
      var result = await getData().dataloader!.getDataAsync(ctx);
      // debugPrint('set getItemsCount ${getData().hashCode} content $result');
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

  void doEvent(CWProviderAction event, CWAppLoaderCtx loader,
      {String? repaintXid}) {
    CWWidgetEvent ctxWE = CWWidgetEvent();
    ctxWE.action = event.toString();
    ctxWE.provider = this;
    ctxWE.loader = loader;
    doAction(null, ctxWE, event);
    if (repaintXid != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        loader.factory.mapWidgetByXid[repaintXid]!.repaint();
      });
    }
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
