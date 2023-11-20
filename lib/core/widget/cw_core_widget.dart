import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';

import '../../designer/cw_factory.dart';
import '../../designer/designer.dart';
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
  void init();
}

mixin CWSlotManager {
  CWWidgetCtx createChildCtx(CWWidgetCtx ctx, String id, int? idx) {
    return CWWidgetCtx('${ctx.xid}$id${idx?.toString() ?? ''}', ctx.loader,
        '${ctx.pathWidget}.$id${idx?.toString() ?? ''}');
  }

  CWWidgetCtx createInArrayCtx(CWWidgetCtx ctx, String id, int? idx) {
    return CWWidgetCtx('${ctx.xid}$id${idx?.toString() ?? ''}', ctx.loader,
        '${ctx.pathWidget}[].$id${idx?.toString() ?? ''}');
  }
}

abstract class CWWidget extends StatefulWidget with CWSlotManager {
  const CWWidget({super.key, required this.ctx});

  final CWWidgetCtx ctx;

  /// affecte les Path des widget de facon recurcive
  /// affecte également les XID by path
  void initSlot(String path);

  void addSlotPath(String pathWid, SlotConfig config) {
    final String childXid = ctx.factory.mapChildXidByXid[config.xid] ?? '';
    //debugPrint('add slot >>>> $pathWid  ${config.xid} childXid=$childXid');
    Widget? widgetChild = ctx.factory.mapWidgetByXid[childXid];

    SlotConfig? old = ctx.factory.mapSlotConstraintByPath[pathWid];
    ctx.factory.mapSlotConstraintByPath[pathWid] = old ?? config;

    if (widgetChild is CWWidget) {
      ctx.factory.mapXidByPath[pathWid] = childXid;
      widgetChild.ctx.pathWidget = pathWid;
      widgetChild.initSlot(pathWid); // appel les enfant
    }
  }

  void repaint() {
    ctx.state.repaint();
  }

  void select() {
    CoreDesigner.emit(CDDesignEvent.select, ctx.getSlot()!.ctx);
  }

  Color? getColor(String id) {
    String? v = ctx.designEntity?.value[id]?['color'];
    return v != null ? Color(int.parse(v, radix: 16)) : null;
  }  

  String getLabel() {
    return ctx.designEntity?.getString('label') ?? '[empty]';
  }    
}

abstract class StateCW<T extends CWWidget> extends State<T> {
  int repaintTime = 0;
  bool mustRepaint = false;
  
  void repaint() {
    if (mounted) {
      repaintTime = DateTime.now().millisecondsSinceEpoch;
      mustRepaint = true;
      setState(() {});
    }
  }

  @override
  void initState() {
    if (widget.ctx.xid != 'root' || widget is! CWSlot) {
      widget.ctx.state = this;
    }
    super.initState();
  }
}

mixin class CWWidgetProvider {
  Future<int> getItemsCountAsync(CWWidgetCtx ctx) async {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      return await provider.getItemsCount(ctx);
    }
    return -1;
  }

  int getItemsCountSync(CWWidgetCtx ctx) {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      return provider.getItemsCountSync();
    }
    return -1;
  }

  void setProviderDataOK(CWProvider? provider, int ok) {
    if (provider != null &&
        provider.loader != null &&
        !provider.loader!.isSync()) {
      CoreGlobalCache.setCache(provider, ok);
    }
  }

  dynamic initFutureDataOrNot(CWProvider? provider, CWWidgetCtx ctx) {
    bool isSync = true;
    if (provider != null &&
        provider.loader != null &&
        !provider.loader!.isSync()) {
      isSync = false;
      String idCache = provider.getProviderCacheID();
      var cacheNbRow = CoreGlobalCache.cacheNbData[idCache];
      if (cacheNbRow != null && cacheNbRow != -1) {
        var result = CoreGlobalCache.cacheDataValue[idCache];
        provider.content = result!;
        return cacheNbRow;
      }
    }
    if (isSync) {
      return getItemsCountSync(ctx);
    } else {
      return getItemsCountAsync(ctx);
    }
  }
}

abstract class CWWidgetMap extends CWWidget with CWWidgetProvider {
  const CWWidgetMap({super.key, required super.ctx});

  void setDisplayRow(InheritedStateContainer? row) {
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

  String getMapString() {
    CWProvider? provider = CWProvider.of(ctx);
    return provider?.getStringValueOf(ctx, 'bind') ?? 'no map';
  }

  bool getMapBool() {
    CWProvider? provider = CWProvider.of(ctx);
    return provider?.getBoolValueOf(ctx, 'bind') ?? false;
  }

  Map<String, dynamic>? getMapOne() {
    CWProvider? provider = CWProvider.of(ctx);
    return provider?.getMapValueOf(ctx, 'bind');
  }

  void setValue(dynamic val) {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      CWWidgetEvent ctxWE = CWWidgetEvent();
      ctxWE.action = CWProviderAction.onValueChanged.toString();
      ctxWE.provider = provider;
      ctxWE.payload = null;
      ctxWE.loader = ctx.loader;
      provider.setValueOf(ctx, ctxWE, 'bind', val);
    }
  }

  void setIdx(int idx) {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      provider.getData().idxDisplayed = idx;
    }
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
        ? GlobalKey(debugLabel: '$xid$prefix')
        : ValueKey('$xid$prefix$change');
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
    CWWidget? widget = factory.mapWidgetByXid[xid ?? ''];
    return widget;
  }

  CWWidget? getCWWidget() {
    String? xid = factory.mapXidByPath[pathWidget];
    CWWidget? widget = factory.mapWidgetByXid[xid ?? ''];
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

  CWWidget? findWidgetByPath(String path) {
    String? xid = factory.mapXidByPath[path];
    CWWidget? widget = factory.mapWidgetByXid[xid ?? ''];
    return widget;
  }

  CWWidget? findSlotByPath(String path) {
    return factory.mapSlotConstraintByPath[path]?.slot;
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
