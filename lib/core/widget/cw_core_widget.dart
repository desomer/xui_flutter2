import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';

import '../../designer/cw_factory.dart';
import '../../designer/selector_manager.dart';
import '../../widget/cw_list.dart';
import '../data/core_data.dart';
import '../data/core_data_query.dart';
import '../data/core_provider.dart';

enum ModeRendering { design, view }

class SlotConfig {
  SlotConfig(this.xid, {this.constraintEntity});
  String xid;
  String? constraintEntity;
  CWSlot? slot;
}

abstract class CWWidgetVirtual {
  CWWidgetVirtual(this.ctx);
  final CWWidgetCtx ctx;
  init();
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

  setDisplayRow(InheritedStateContainer? row) {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      if (row != null) {
        //print("row.index = ${row.index}");
        provider.getData().idxDisplayed = row.index!;
      }
    }
  }

  InheritedStateContainer? getRowState(BuildContext context) {
    InheritedStateContainer? row =
        context.getInheritedWidgetOfExactType<InheritedStateContainer>();
    return row;
  }

  String getMapValue() {
    CWProvider? provider = CWProvider.of(ctx);
    return provider?.getStringValueOf(ctx, "bind") ?? "no map";
  }

  bool getMapBool() {
    CWProvider? provider = CWProvider.of(ctx);
    return provider?.getBoolValueOf(ctx, "bind") ?? false;
  }

  void setValue(dynamic val) {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      CWWidgetEvent ctxWE = CWWidgetEvent();
      ctxWE.action = CWProviderAction.onValueChanged.toString();
      ctxWE.provider = provider;
      ctxWE.payload = null;
      ctxWE.loader = ctx.loader;
      provider.setValueOf(ctx, ctxWE, "bind", val);
    }
  }

  Future<int> getItemsCountAsync() async {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      return await provider.getItemsCount();
    }
    return -1;
  }

  int getItemsCountSync() {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      return provider.getItemsCountSync();
    }
    return -1;
  }

  setProviderDataOK(CWProvider? provider, int ok) {
    if (provider != null &&
        provider.loader != null &&
        !provider.loader!.isSync()) {
      CoreGlobalCacheResultQuery.setCache(provider, ok);
    }
  }

  dynamic initFutureDataOrNot(CWProvider? provider) {
    bool isSync = true;
    if (provider != null &&
        provider.loader != null &&
        !provider.loader!.isSync()) {
      isSync = false;
      String idCache = provider.name + provider.type;
      var cacheNbRow = CoreGlobalCacheResultQuery.cacheNbData[idCache];
      if (cacheNbRow != null && cacheNbRow != -1) {
        var result = CoreGlobalCacheResultQuery.cacheDataValue[idCache];
        provider.content = result!;
        return cacheNbRow;
      }
    }
    if (isSync) {
      return getItemsCountSync();
    } else {
      return getItemsCountAsync();
    }
  }

  void setIdx(int idx) {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      provider.getData().idxDisplayed = idx;
    }
  }

  String getLabel() {
    return ctx.designEntity?.getString('label') ?? '[empty]';
  }

  int getCountChildren() {
    return ctx.designEntity?.getInt('count', 0) ?? 0;
  }
}

class CWWidgetCtx {
  CWWidgetCtx(this.xid, this.loader, this.pathWidget);
  String xid;
  String pathWidget;
  CWAppLoaderCtx loader;
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
    //TODO a retirer customAlphabet  mais bug affichage des attributs
    return loader.mode == ModeRendering.design
        ? GlobalKey(debugLabel: xid)
        : ValueKey('$xid${customAlphabet('1234567890abcdef', 10)}');
  }

  Key? getSlotKey(String prefix, String change) {
    return loader.mode == ModeRendering.design
        ? GlobalKey(debugLabel: "$xid$prefix")
        : ValueKey("$xid$prefix$change");
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

  CWWidget? findWidgetByXid(String xid) {
    return factory.mapWidgetByXid[xid];
  }

  void changeProp(String name, dynamic val) {
    designEntity?.value[name] = val;
  }
}

class CWWidgetEvent {
  CWWidgetCtx? widgetCtx;
  String? action;
  dynamic payload;
  CWProvider? provider;
  CWAppLoaderCtx? loader;
  dynamic ret;
  String? retAction;
}
