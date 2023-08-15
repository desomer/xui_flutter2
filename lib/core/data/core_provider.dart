import 'package:xui_flutter/core/data/core_data_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';

import '../widget/cw_core_widget.dart';
import 'core_data.dart';
import 'core_data_query.dart';

enum CWProviderAction {
  onFactoryMountWidget, //attribut mount sur un widget avec la prop
  onMapWidget, // permet de renvoyer le type de widget à Mapper
  onStateNone,
  onStateNone2Create,
  onStateDelete,
  onValueChanged,
  onRowSelected
}

class CWProvider {
  CWProvider(this.name, this.type, this.loader);

  String name;
  CoreDataEntity? header;
  String type;

  List<CoreDataEntity> content = [];

  int idxDisplayed = -1;
  int idxSelected = -1;
  Map<CWProviderAction, List<CoreDataAction>> actions = {};
  Map<String, List<CoreDataAction>> userActions = {};
  CoreDataLoader? loader;

  setFilter(CoreDataEntity? aFilter) {
    loader?.setFilter(aFilter);
  }

  add(CoreDataEntity add) {
    content.add(add);
    if (idxDisplayed == -1) idxDisplayed = 0;
  }

  addNew(CoreDataEntity newRow) {
    if (loader != null) {
      loader?.addData(newRow);
    }
    add(newRow);

    CoreGlobalCacheResultQuery.notifNewRow(this);
  }

  CoreDataEntity getEntityByIdx(idx) {
    return content[idx];
  }

  CoreDataEntity getDisplayedEntity() {
    return content[idxDisplayed];
  }

  CoreDataEntity? getSelectedEntity() {
    if (idxSelected == -1) return null;
    if (idxSelected >= content.length) {
      idxSelected = -1;
      return null;
    }
    return content[idxSelected];
  }

  CWProvider addAction(CWProviderAction idAction, CoreDataAction action) {
    if (actions[idAction] == null) actions[idAction] = [];
    actions[idAction]!.add(action);
    return this;
  }

  CWProvider addUserAction(String idAction, CoreDataAction action) {
    if (userActions[idAction] == null) userActions[idAction] = [];
    userActions[idAction]!.add(action);
    return this;
  }

  CWProvider doAction(
      CWWidgetCtx? ctx, CWWidgetEvent? event, CWProviderAction idAction) {
    event?.widgetCtx = ctx;
    if (actions[idAction] != null) {
      for (var act in actions[idAction]!) {
        act.execute(ctx, event);
      }
    }
    return this;
  }

  CWProvider doUserAction(
      CWWidgetCtx? ctx, CWWidgetEvent? event, String idAction) {
    event?.widgetCtx = ctx;
    if (userActions[idAction] != null) {
      for (var act in userActions[idAction]!) {
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
    var val = getDisplayedEntity().value[ctx.designEntity?.getString(propName)];
    return val?.toString() ?? "";
  }

  bool getBoolValueOf(CWWidgetCtx ctx, String propName) {
    var val = getDisplayedEntity().value[ctx.designEntity?.getString(propName)];
    return val ?? false;
  }

  void setValueOf(
      CWWidgetCtx ctx, CWWidgetEvent? event, String propName, dynamic val) {
    dynamic v = val;
    CoreDataAttribut? attr = getDisplayedEntity().getAttrByName(
        ctx.loader.collectionDataModel, ctx.designEntity!.getString(propName)!);
    if (attr?.type == CDAttributType.CDint) {
      v = int.tryParse(val);
    }
    else if (attr?.type == CDAttributType.CDdec) {
      v = double.tryParse(val);
    }  
       
    getDisplayedEntity().setAttr(ctx.loader.collectionDataModel,
        ctx.designEntity!.getString(propName)!, v);

    var displayedEntity = getDisplayedEntity();

    var rowOperation = displayedEntity.operation;
    if (rowOperation == CDAction.none) {
      doAction(ctx, event, CWProviderAction.onStateNone2Create);
    }
    doAction(ctx, event, CWProviderAction.onValueChanged);

    loader?.changed(this, displayedEntity);
  }

  Future<int> getItemsCount() async {
    if (loader != null) {
      var result = await loader!.getDataAsync();
      content = result;
      CoreGlobalCacheResultQuery.setCacheValue(this, content);
    }
    return content.length;
  }

  int getItemsCountSync() {
    if (loader != null) {
      var result = loader!.getDataSync();
      content = result;
    }
    return content.length;
  }

  void doEvent(CWProviderAction event, CWWidgetLoaderCtx loader,
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
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    fct(event);
  }
}
