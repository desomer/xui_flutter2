import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';

import '../../designer/selector_manager.dart';
import '../data/core_data.dart';
import '../data/core_provider.dart';
import '../../designer/cw_factory.dart';

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
        '${ctx.pathWidget}.$id${idx?.toString() ?? ''}');
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

abstract class CWWidgetMap extends CWWidget {
  const CWWidgetMap({super.key, required super.ctx});

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

  int getItemsCount() {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      return provider.content.length;
    }
    return -1;
  }

  void setIdx(int idx) {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      provider.idx = idx;
    }
  }

  String getLabel() {
    return ctx.designEntity?.getString('label') ?? '[empty]';
  }
}

class CWWidgetCtx {
  CWWidgetCtx(this.xid, this.factory, this.pathWidget);
  String xid;
  String pathWidget;
  WidgetFactoryEventHandler factory;
  CoreDataEntity? designEntity;
  String? pathDataDesign;
  String? pathDataCreate;
  CWSlot? inSlot;
  dynamic lastEvent;

  GlobalKey? getKey() {
    return factory.modeRendering == ModeRendering.design
        ? GlobalKey(debugLabel: xid)
        : null;
  }

  GlobalKey? getSlotKey(String prefix) {
    return factory.modeRendering == ModeRendering.design
        ? GlobalKey(debugLabel: "$xid$prefix")
        : null;
  }

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
    String? xid = factory.mapXidByPath[getParentPath()];
    CWWidget? widget = factory.mapWidgetByXid[xid ?? ""];
    return widget;
  }

  CWWidget? getCWWidget() {
    String? xid = factory.mapXidByPath[pathWidget];
    CWWidget? widget = factory.mapWidgetByXid[xid ?? ""];
    return widget;
  }

  CWSlot? getSlot() {
    return factory.mapSlotConstraintByPath[pathWidget]?.slot;
  }

  CWWidgetCtx refreshContext() {
    CWWidget? wid = factory.mapWidgetByXid[xid];
    if (wid == null) {
      SlotConfig? slotConfig = factory.mapSlotConstraintByPath[pathWidget];
      inSlot = slotConfig?.slot;
    } else {
      inSlot = wid.ctx.inSlot;
    }
    return this;
  }

  bool isSelected() {
    return CoreDesignerSelector.of().isSelectedWidget(this);
  }

  CWWidget? getWidgetInSlot() {
    final String childXid = factory.mapChildXidByXid[xid] ?? '';
    return factory.mapWidgetByXid[childXid];
  }
}

class CWWidgetEvent {
  String? action;
  dynamic payload;
}
