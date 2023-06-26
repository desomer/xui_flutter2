
import '../widget/cw_core_widget.dart';
import 'core_data.dart';

enum CWProviderAction { onStateCreate, onChange }

class CWProvider {
  CWProvider(this.current);
  CoreDataEntity current;
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
    CWProvider? provider = ctx
        .factory.mapProvider[ctx.entityForFactory?.getString('providerName')];
    return provider;
  }

  String getStringValueOf(CWWidgetCtx ctx, String propName) {
    dynamic val = current.value[ctx.entityForFactory?.getString(propName)];
    return val?.toString() ?? "";
  }

  bool getBoolValueOf(CWWidgetCtx ctx, String propName) {
    dynamic val = current.value[ctx.entityForFactory?.getString(propName)];
    return val ?? false;
  }  

  void setValueOf(
      CWWidgetCtx ctx, CWWidgetEvent? event, String propName, dynamic val) {
    dynamic v = val;
    CoreDataAttribut? attr = current.getAttrByName(
        ctx.factory.collection, ctx.entityForFactory!.getString(propName)!);
    if (attr?.type == CDAttributType.CDint) {
      v = int.tryParse(val);
    }
    current.setAttr(
        ctx.factory.collection, ctx.entityForFactory!.getString(propName)!, v);

    if (current.operation == CDAction.none) {
      current.operation = CDAction.create;
    doAction(ctx, event, CWProviderAction.onStateCreate);
    }
    doAction(ctx, event, CWProviderAction.onChange);
  }
}

abstract class CoreDataAction {
  dynamic execute(CWWidgetCtx ctx, CWWidgetEvent? event);
}

