import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';

import '../../designer/designer.dart';
import '../data/core_data.dart';
import '../data/core_provider.dart';
import 'cw_factory.dart';

enum ModeRendering { design, view }

class SlotConfig {
  SlotConfig(this.xid, {this.constraintEntity});
  String xid;
  String? constraintEntity;
  CWSlot? slot;
}

abstract class CWWidget extends StatefulWidget {
  const CWWidget({super.key, required this.ctx});
  final CWWidgetCtx ctx;

  initSlot(String path);

  void addSlotPath(String pathWid, SlotConfig config) {
    final String childXid = ctx.factory.mapChildXidByXid[config.xid] ?? '';
    //debugPrint('add slot >>>> $pathWid  ${config.xid} childXid=$childXid');
    Widget? w = ctx.factory.mapWidgetByXid[childXid];

    SlotConfig? old = ctx.factory.mapSlotConstraintByPath[pathWid];
    ctx.factory.mapSlotConstraintByPath[pathWid] = old ?? config;

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

  void repaint() {
    ((key as GlobalKey).currentState as StateCW?)?.repaint();
  }
}

abstract class StateCW<T extends StatefulWidget> extends State<T> {
  void repaint() {
    setState(() {});
  }
}

abstract class CWWidgetInput extends CWWidget {
  const CWWidgetInput({super.key, required super.ctx});

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
  CWSlot? slot;
  dynamic lastEvent;

  static String getParentPathFrom(String path) {
    String p = path;
    int i = p.lastIndexOf('.');
    if (i > 0) {
      p = p.substring(0, i);
    }
    return p;
  }

  String getParentPath() {
    String p = pathWidget;
    int i = p.lastIndexOf('.');
    if (i > 0) {
      p = p.substring(0, i);
    }
    return p;
  }

  CWWidget? getParentCWWidget() {
    WidgetFactoryEventHandler factory = CoreDesigner.of().factory;

    String? xid = factory.mapXidByPath[getParentPath()];
    CWWidget? widget = factory.mapWidgetByXid[xid ?? ""];
    return widget;
  }
}

class CWWidgetEvent {
  String? action;
  dynamic payload;
}
