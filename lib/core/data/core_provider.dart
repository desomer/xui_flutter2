import '../widget/cw_core_widget.dart';
import 'core_data.dart';

enum CWProviderAction { onStateCreate, onChange, onMountWidget }

class CWProvider {
  CWProvider();
  List<CoreDataEntity> content = [];
  int idx = -1;

  add(CoreDataEntity add) {
    content.add(add);
    if (idx == -1) idx = 0;
  }

  CoreDataEntity getCurrent() {
    return content[idx];
  }

  Map<CWProviderAction, List<CoreDataAction>> actions = {};

  CWProvider addAction(CWProviderAction idAction, CoreDataAction action) {
    if (actions[idAction] == null) actions[idAction] = [];
    actions[idAction]!.add(action);
    return this;
  }

  CWProvider doAction(
      CWWidgetCtx ctx, CWWidgetEvent? event, CWProviderAction idAction) {
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
    dynamic val = getCurrent().value[ctx.designEntity?.getString(propName)];
    return val?.toString() ?? "";
  }

  bool getBoolValueOf(CWWidgetCtx ctx, String propName) {
    dynamic val = getCurrent().value[ctx.designEntity?.getString(propName)];
    return val ?? false;
  }

  void setValueOf(
      CWWidgetCtx ctx, CWWidgetEvent? event, String propName, dynamic val) {
    dynamic v = val;
    CoreDataAttribut? attr = getCurrent().getAttrByName(
        ctx.factory.collection, ctx.designEntity!.getString(propName)!);
    if (attr?.type == CDAttributType.CDint) {
      v = int.tryParse(val);
    }
    getCurrent().setAttr(
        ctx.factory.collection, ctx.designEntity!.getString(propName)!, v);

    if (getCurrent().operation == CDAction.none) {
      getCurrent().operation = CDAction.create;
      doAction(ctx, event, CWProviderAction.onStateCreate);
    }
    doAction(ctx, event, CWProviderAction.onChange);
  }
}

abstract class CoreDataAction {
  dynamic execute(CWWidgetCtx ctx, CWWidgetEvent? event);
}
