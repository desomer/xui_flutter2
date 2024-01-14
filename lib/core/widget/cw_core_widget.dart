import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';

import '../../designer/application_manager.dart';
import '../../designer/builder/prop_builder.dart';
import '../../designer/cw_factory.dart';
import '../../designer/designer.dart';
import '../../designer/selector_manager.dart';
import '../../widget/cw_list.dart';
import '../data/core_data.dart';
import '../data/core_data_query.dart';
import '../data/core_provider.dart';

enum ModeRendering { design, view }

const String iDCount = '_count_';

class SlotConfig {
  SlotConfig(this.xid,
      {this.constraintEntity, this.ctxVirtualSlot, this.pathNested});
  String xid;
  String? constraintEntity;
  CWSlot? slot;
  CWWidgetCtx? ctxVirtualSlot;
  String? pathNested;
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

class CWStyledBox {
  CWStyledBox(this.widget) {
    style = widget.ctx.designEntity?.getOne('_style_');
  }

  final CWWidget widget;
  late Map<String, dynamic>? style;

  bool styleExist(List<String> properties) {
    style = widget.ctx.designEntity?.getOne('_style_');
    for (var p in properties) {
      if (style?[p] != null) {
        return true;
      }
    }
    return false;
  }

  double getStyleDouble(String id, double def) {
    return style?[id] ?? def;
  }

  double? getStyleNDouble(String id) {
    return style?[id];
  }

  double? getElevation() {
    return getStyleNDouble('elevation');
  }

  Color? getColor(String id) {
    var oneValue = style?[id];
    return oneValue != null
        ? Color(int.parse(oneValue['color'], radix: 16))
        : null;
  }

  // Offset dragAnchorStrategy(
  //     Draggable<Object> d, BuildContext context, Offset point) {
  //   return Offset(d.feedbackOffset.dx + 10, d.feedbackOffset.dy + 10);
  // }

  Widget getDragPaddding(Widget w) {
    return Draggable<String>(
      onDragUpdate: (details) {
        print(details);

        CoreDataEntity prop = PropBuilder.preparePropChange(
            widget.ctx.loader, DesignCtx().forDesign(widget.ctx));

        Map<String, dynamic>? s = prop.value['_style_'];
        var alignX = s?['boxAlignHorizontal'] ?? '-1';
        var alignY = s?['boxAlignVertical'] ?? '-1';

        if (alignY == '-1' || alignY == '0') {
          double vy = s?['ptop'] ?? 0;
          s?['ptop'] = max(0.0, vy + details.delta.dy);
        } else {
          double vy = s?['pbottom'] ?? 0;
          s?['pbottom'] = max(0.0, vy - details.delta.dy);
        }
        if (alignX == '-1' || alignX == '0') {
          double vx = s?['pleft'] ?? 0;
          s?['pleft'] = max(0.0, vx + details.delta.dx);
        } else {
          double vx = s?['pright'] ?? 0;
          s?['pright'] = max(0.0, vx - details.delta.dx);
        }

        widget.repaint();
        CoreDesigner.emit(CDDesignEvent.reselect, null);
      },
      //dragAnchorStrategy: dragAnchorStrategy,
      data: 'drag',
      feedback: Container(),
      child: w,
    );
  }

  Widget getStyledBox(Widget content) {
    if (style == null) {
      return content;
    }
    AlignmentDirectional? align;
    if (styleExist(['boxAlignVertical', 'boxAlignHorizontal'])) {
      align = AlignmentDirectional(
          double.parse(style!['boxAlignHorizontal'] ?? '-1'),
          double.parse(style!['boxAlignVertical'] ?? '-1'));
    }

    widget.ctx.infoSelector.withPadding = false;
    if (styleExist(['pleft', 'ptop', 'pright', 'pbottom'])) {
      EdgeInsets padding = EdgeInsets.fromLTRB(
          getStyleDouble('pleft', 0),
          getStyleDouble('ptop', 0),
          getStyleDouble('pright', 0),
          getStyleDouble('pbottom', 0));
      content = Padding(
          key: widget.ctx.getContentKey(true),
          padding: padding,
          child: content);
    }

    return Container(alignment: align, child: getDragPaddding(content));
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

  CWProvider? getProvider() {
    return CWProvider.of(ctx);
  }

  void repaint() {
    ctx.state.repaint();
  }

  void select() {
    CoreDesigner.emit(CDDesignEvent.select, ctx.getSlot()!.ctx);
  }

  //--------------------------------------------------------
  int? getInt(String id, int? def) {
    return ctx.designEntity?.getInt(id, def);
  }

  Color? getColor(String id) {
    String? v = ctx.designEntity?.value[id]?['color'];
    return v != null ? Color(int.parse(v, radix: 16)) : null;
  }

  String getLabel(String def) {
    var bind = ctx.designEntity?.getOne('@label');
    if (bind != null) {
      return getMapString(provInfo: bind);
    }
    var mode = CWApplication.of().loaderDesigner.mode;
    return ctx.designEntity?.getString('label') ??
        (mode == ModeRendering.design ? def : '');
  }

  Map<String, dynamic>? getIcon() {
    return ctx.designEntity?.value['icon'];
  }

  //--------------------------------------------------------

  String getMapString({Map<String, dynamic>? provInfo}) {
    if (provInfo != null) {
      var mode = ctx.loader.mode;
      //  CWApplication.of().loaderDesigner.mode;
      CWProvider? provider = CWProvider.of(ctx, id: provInfo[iDProviderName]);
      var val = (provider?.displayRenderingMode == DisplayRenderingMode.selected
              ? provider?.getSelectedEntity()
              : provider?.getDisplayedEntity())
          ?.value[provInfo[iDBind]];
      if (val == null && provider != null) {
        if (mode == ModeRendering.design) {
          var nameAttr = provider.getAttrName(provInfo[iDBind]);
          return '[@$nameAttr]';
        } else {
          return '';
        }
      } else {
        return val!.toString();
      }
    } else {
      CWProvider? provider = CWProvider.of(ctx);
      return provider?.getStringValueOf(ctx, iDBind) ?? 'no map';
    }
  }

  bool getMapBool() {
    CWProvider? provider = CWProvider.of(ctx);
    return provider?.getBoolValueOf(ctx, iDBind) ?? false;
  }

  double? getMapDouble() {
    CWProvider? provider = CWProvider.of(ctx);
    return provider?.getDoubleValueOf(ctx, iDBind);
  }

  Map<String, dynamic>? getMapOne(String id) {
    CWProvider? provider = CWProvider.of(ctx);
    return provider?.getMapValueOf(ctx, id);
  }
}

abstract class StateCW<T extends CWWidget> extends State<T> {
  int repaintTime = 0;
  bool mustRepaint = false;
  late CWStyledBox styledBox;

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
      styledBox = CWStyledBox(widget);
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

abstract class CWWidgetChild extends CWWidget {
  const CWWidgetChild({super.key, required super.ctx});
  int getDefChild(String id);

  int getNbChild(String id, int def) {
    return ctx.designEntity?.getInt(id, def) ?? def;
  }
}

abstract class CWWidgetMapLabel extends CWWidgetMapValue {
  const CWWidgetMapLabel({super.key, required super.ctx});
}

abstract class CWWidgetMapValue extends CWWidget with CWWidgetProvider {
  const CWWidgetMapValue({super.key, required super.ctx});

  @override
  CWProvider? getProvider() {
    var bind =
        ctx.designEntity?.getOne(this is CWWidgetMapLabel ? '@label' : '@bind');
    if (bind != null) {
      return CWProvider.of(ctx, id: bind[iDProviderName]);
    }
    return CWProvider.of(ctx);
  }

  InheritedStateContainer? getRowState(BuildContext context) {
    InheritedStateContainer? row =
        context.getInheritedWidgetOfExactType<InheritedStateContainer>();
    return row;
  }

  void setDisplayRow(InheritedStateContainer? row) {
    CWProvider? provider = getProvider();
    if (provider != null) {
      if (row != null) {
        //print("row.index = ${row.index}");
        provider.displayRenderingMode = DisplayRenderingMode.displayed;
        provider.getData().idxDisplayed = row.index!;
      }
    }
  }

  void setValue(dynamic val, {Map<String, dynamic>? provInfo}) {
    if (provInfo != null) {
      CWProvider? provider = CWProvider.of(ctx, id: provInfo[iDProviderName]);
      if (provider != null) {
        CWWidgetEvent ctxWE = CWWidgetEvent();
        ctxWE.action = CWProviderAction.onValueChanged.toString();
        ctxWE.provider = provider;
        ctxWE.payload = null;
        ctxWE.loader = ctx.loader;
        provider.setValueOf(ctx, ctxWE, provInfo[iDBind], val);
      }
    } else {
      CWProvider? provider = CWProvider.of(ctx);
      if (provider != null) {
        CWWidgetEvent ctxWE = CWWidgetEvent();
        ctxWE.action = CWProviderAction.onValueChanged.toString();
        ctxWE.provider = provider;
        ctxWE.payload = null;
        ctxWE.loader = ctx.loader;
        provider.setValuePropOf(ctx, ctxWE, iDBind, val);
      }
    }
  }
}

abstract class CWWidgetMapProvider extends CWWidget with CWWidgetProvider {
  const CWWidgetMapProvider({super.key, required super.ctx});

  void setIdx(int idx) {
    CWProvider? provider = CWProvider.of(ctx);
    if (provider != null) {
      provider.getData().idxDisplayed = idx;
    }
  }

  int getCountChildren() {
    return ctx.designEntity?.getInt(iDCount, 0) ?? 0;
  }
}

////////////////////////////////////////////////////////////////////////
class CWWidgetInfoSelector {
  CWWidgetInfoSelector({this.slotKey, this.contentKey});

  bool withPadding = false;
  GlobalKey? contentKey;
  GlobalKey? slotKey;
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
  CWWidgetInfoSelector infoSelector = CWWidgetInfoSelector();

  WidgetFactoryEventHandler get factory {
    return loader.factory;
  }

  Key? getContentKey(bool padding) {
    var k = getKey();
    if (padding) infoSelector.withPadding = true;
    if (k is GlobalKey) infoSelector.contentKey = k;
    return k;
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
  BuildContext? buildContext;
  CWWidgetCtx? widgetCtx;
  String? action;
  dynamic payload;
  CWProvider? provider;
  CWAppLoaderCtx? loader;
  dynamic ret;
  String? retAction;
}
