import 'package:xui_flutter/core/data/core_data_loader.dart';

import '../widget/cw_core_widget.dart';
import 'core_data.dart';
import 'core_data_query.dart';

enum CWProviderAction {
  onNone2Create,
  onInsertNone,
  onChange,
  onBuild,
  onMountWidget,
  onSelected
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
  CoreDataLoader? loader;

  add(CoreDataEntity add) {
    content.add(add);
    if (idxDisplayed == -1) idxDisplayed = 0;
  }

  addNew(CoreDataEntity newRow) {
    if (loader != null) {
      loader?.addData(newRow);
    }
    add(newRow);

    CacheResultQuery.notifNewRow(this);
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

  CWProvider doAction(
      CWWidgetCtx? ctx, CWWidgetEvent? event, CWProviderAction idAction) {
    if (actions[idAction] != null) {
      for (var act in actions[idAction]!) {
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
    dynamic val =
        getDisplayedEntity().value[ctx.designEntity?.getString(propName)];
    return val?.toString() ?? "";
  }

  bool getBoolValueOf(CWWidgetCtx ctx, String propName) {
    dynamic val =
        getDisplayedEntity().value[ctx.designEntity?.getString(propName)];
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
    getDisplayedEntity().setAttr(ctx.loader.collectionDataModel,
        ctx.designEntity!.getString(propName)!, v);

    var displayedEntity = getDisplayedEntity();
    var rowOperation = displayedEntity.operation;

    if (rowOperation == CDAction.none) {
      displayedEntity.operation = CDAction.create;
      doAction(ctx, event, CWProviderAction.onNone2Create);
    }
    if (rowOperation == CDAction.read) {
      displayedEntity.operation == CDAction.update;
    }
    doAction(ctx, event, CWProviderAction.onChange);
  }

  Future<int> getItemsCount() async {
    if (loader != null) {
      var result = await loader!.getData(null);
      content=result;
      CacheResultQuery.setCacheValue(this, content);
    }
    return content.length;
  }

  int getItemsCountSync() {
    if (loader != null) {
      var result = loader!.getDataSync(null);
      content=result;
    }
    return content.length;
  }  
}

abstract class CoreDataAction {
  dynamic execute(CWWidgetCtx? ctx, CWWidgetEvent? event);
}
