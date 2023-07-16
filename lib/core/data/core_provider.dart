import 'package:xui_flutter/core/data/core_data_loader.dart';

import '../widget/cw_core_widget.dart';
import 'core_data.dart';

enum CWProviderAction {
  onNone2Create,
  onChange,
  onInsertNone,
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

  CoreDataEntity getEntityByIdx(idx) {
    return content[idx];
  }

  CoreDataEntity getDisplayedEntity() {
    return content[idxDisplayed];
  }

  CoreDataEntity getSelectedEntity() {
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
        ctx.loader.collectionAppli, ctx.designEntity!.getString(propName)!);
    if (attr?.type == CDAttributType.CDint) {
      v = int.tryParse(val);
    }
    getDisplayedEntity().setAttr(
        ctx.loader.collectionAppli, ctx.designEntity!.getString(propName)!, v);

    if (getDisplayedEntity().operation == CDAction.none) {
      getDisplayedEntity().operation = CDAction.create;
      doAction(ctx, event, CWProviderAction.onNone2Create);
    }
    doAction(ctx, event, CWProviderAction.onChange);
  }
}

abstract class CoreDataAction {
  dynamic execute(CWWidgetCtx? ctx, CWWidgetEvent? event);
}
