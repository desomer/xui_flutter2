import 'package:flutter/material.dart';

import '../data/core_data.dart';
import '../data/core_provider.dart';
import 'cw_factory.dart';

enum ModeRendering { design, view }

class SlotConfig {
  SlotConfig(this.xid, {this.constraintEntity});
  String xid;
  String? constraintEntity;
}

// ignore: must_be_immutable
abstract class CWWidget extends StatefulWidget {
  CWWidget({super.key, required this.ctx});
  CWWidgetCtx ctx;
  initSlot(String path);

  void addSlotPath(String pathWid, SlotConfig config) {
    final String childXid = ctx.factory.mapChildXidByXid[config.xid] ?? '';
    debugPrint('add slot >>>> $pathWid  ${config.xid} childXid=$childXid');
    Widget? w = ctx.factory.mapWidgetByXid[childXid];
    ctx.factory.mapSlotConstraintByPath[pathWid] = config;

    if (w is CWWidget) {
      ctx.factory.mapXidByPath[pathWid] = childXid;
      w.ctx.pathWidget = pathWid;
      w.initSlot(pathWid); // appel les enfant
    }
  }

  CWWidgetCtx createChildCtx(String id, int? idx) {
    return CWWidgetCtx('${ctx.xid}$id${idx?.toString() ?? ''}', ctx.factory,
        '${ctx.pathWidget}.$id${idx?.toString() ?? ''}', ctx.modeRendering);
  }
}

// ignore: must_be_immutable
abstract class CWWidgetInput extends CWWidget {
  CWWidgetInput({super.key, required super.ctx});

  String getValue() {
    CWProvider? provider = CWProvider.of(ctx);
    return provider?.getStringValueOf(ctx, "bind") ?? "no map";
  }

  bool getBool() {
    CWProvider? provider = CWProvider.of(ctx);
    return provider?.getBoolValueOf(ctx, "bind") ?? false;
  }

  void setValue(dynamic val) {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      provider.setValueOf(ctx, null, "bind", val);
    }
  }

  String getLabel() {
    return ctx.entityForFactory?.getString('label') ?? '[empty]';
  }
}

class CWWidgetCtx {
  CWWidgetCtx(this.xid, this.factory, this.pathWidget, this.modeRendering);
  ModeRendering modeRendering;
  String xid;
  String pathWidget;
  WidgetFactoryEventHandler factory;
  CoreDataEntity? entityForFactory;
  String? pathDataDesign;
  String? pathDataCreate;
}

class CWWidgetEvent {
  String? action;
  dynamic payload;
}
