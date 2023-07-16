import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';

import '../../designer/cw_factory.dart';
import '../../designer/selector_manager.dart';
import '../../widget/cw_list.dart';
import '../data/core_data.dart';
import '../data/core_provider.dart';

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
    return CWWidgetCtx('${ctx.xid}$id${idx?.toString() ?? ''}', ctx.loader,
        '${ctx.pathWidget}.$id${idx?.toString() ?? ''}');
  }

  CWWidgetCtx createInArrayCtx(String id, int? idx) {
    return CWWidgetCtx('${ctx.xid}$id${idx?.toString() ?? ''}', ctx.loader,
        '${ctx.pathWidget}[].$id${idx?.toString() ?? ''}');
  }

  void repaint() {
    //var state = ((key as GlobalKey).currentState as StateCW?);
    ctx.state.repaint();
    //state?.repaint();
  }
}

abstract class StateCW<T extends CWWidget> extends State<T> {
  void repaint() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    if (widget.ctx.xid != "root" || widget is! CWSlot) {
      widget.ctx.state = this;
    }
    super.initState();
  }
}

abstract class CWWidgetMap extends CWWidget {
  const CWWidgetMap({super.key, required super.ctx});

  initRow(BuildContext context) {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      InheritedStateContainer? row =
          context.getInheritedWidgetOfExactType<InheritedStateContainer>();
      if (row != null) {
        // print("row.index = ${row.index}");
        provider.idxDisplayed = row.index!;
      }
    }
  }

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
      if (provider.loader != null) {
        provider.content.clear();
        provider.content.addAll(provider.loader!.getData(null));
      }
      return provider.content.length;
    }
    return -1;
  }

  void setIdx(int idx) {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      provider.idxDisplayed = idx;
    }
  }

  String getLabel() {
    return ctx.designEntity?.getString('label') ?? '[empty]';
  }
}

class CWWidgetCtx {
  CWWidgetCtx(this.xid, this.loader, this.pathWidget);
  String xid;
  String pathWidget;
  CWWidgetLoaderCtx loader;
  CoreDataEntity? designEntity;
  String? pathDataDesign;
  String? pathDataCreate;
  CWSlot? inSlot;
  dynamic lastEvent;
  late StateCW state;

  WidgetFactoryEventHandler get factory {
    return loader.factory;
  }

  Key? getKey() {
    return loader.mode == ModeRendering.design
        ? GlobalKey(debugLabel: xid)
        : ValueKey("$xid${customAlphabet('1234567890abcdef', 10)}");
    // : (force
    //     ? GlobalStringKey(customAlphabet('1234567890abcdef', 10))
    //     : null);
  }

  Key? getSlotKey(String prefix) {
    return loader.mode == ModeRendering.design
        ? GlobalKey(debugLabel: "$xid$prefix")
        : ValueKey("$xid$prefix${customAlphabet('1234567890abcdef', 10)}");
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

  CWWidgetCtx? findByXid(String xid) {
    return factory.mapWidgetByXid[xid]?.ctx;
  }

  void changeProp(String name, dynamic val) {
    designEntity?.value[name] = val;
  }
}

class CWWidgetEvent {
  String? action;
  dynamic payload;
  CWProvider? provider;
  CWWidgetLoaderCtx? loader;
  dynamic ret;
}
