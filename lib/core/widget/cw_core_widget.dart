import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';

import '../../designer/application_manager.dart';
import 'cw_core_styledbox.dart';
import 'cw_factory.dart';
import '../../designer/designer.dart';
import '../../designer/selector_manager.dart';
import '../../widget/cw_list.dart';
import '../data/core_data.dart';
import '../data/core_data_query.dart';
import '../data/core_repository.dart';

enum ModeRendering { design, view }

const String iDCount = '_count_';

class XidBuilder {
  XidBuilder({this.tag, this.idx, this.post});

  String? tag;
  String? post;
  int? idx;

  String getSlotXid(String xid) {
    String ret = xid;
    if (tag != null) ret = ret + tag!;
    if (idx != null) ret = ret + idx.toString();
    if (post != null) ret = ret + post!;
    return ret;
  }
}

class SlotConfig {
  SlotConfig(this.xidbuilder, this.xidParent,
      {this.constraintEntity, this.ctxVirtualSlot, this.pathNested});
  XidBuilder xidbuilder;
  String xidParent;
  String? constraintEntity;
  CWSlot? slot;
  CWWidgetCtx? ctxVirtualSlot;
  String? pathNested;

  String get xid {
    return xidbuilder.getSlotXid(xidParent);
  }
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
  void initSlot(String path, ModeParseSlot mode);

  void addSlotPath(String pathWid, SlotConfig config, ModeParseSlot mode) {
    var xid = config.xid;
    final String childXid = ctx.factory.mapChildXidByXid[xid] ?? '';

    if (mode == ModeParseSlot.save) {
      // gestion du link entre composant Provider
      debugPrint(
          'add slot >>>> $pathWid  xid=$xid child Xid=$childXid');
      var app = CWApplication.of();
      var listUseXid = app.linkInfo.listUseXid;
      listUseXid[xid] = 1 + (listUseXid[xid] ?? 0);
      if (childXid != '') {
        listUseXid[childXid] = (listUseXid[childXid] ?? 0);
      }
    }

    Widget? widgetChild = ctx.factory.mapWidgetByXid[childXid];

    SlotConfig? old = ctx.factory.mapSlotConstraintByPath[pathWid];
    ctx.factory.mapSlotConstraintByPath[pathWid] = old ?? config;

    if (widgetChild is CWWidget) {
      ctx.factory.mapXidByPath[pathWid] = childXid;
      widgetChild.ctx.pathWidget = pathWid;
      widgetChild.initSlot(pathWid, mode); // appel les enfant
    }
  }

  CWRepository? getRepository() {
    return CWRepository.of(ctx);
  }

  void repaint() {
    ctx.state?.repaint();
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

  String? getLabelOrNull(String? def) {
    var bind = ctx.designEntity?.getOne('@label');
    if (bind != null) {
      return getMapString(provInfo: bind);
    }
    var mode = CWApplication.of().loaderDesigner.mode;
    return ctx.designEntity?.getString('label') ??
        (mode == ModeRendering.design ? def : null);
  }

  Map<String, dynamic>? getIcon() {
    return ctx.designEntity?.value['icon'];
  }

  //--------------------------------------------------------

  String getMapString({Map<String, dynamic>? provInfo}) {
    if (provInfo != null) {
      var mode = ctx.loader.mode;
      //  CWApplication.of().loaderDesigner.mode;
      CWRepository? provider =
          CWRepository.of(ctx, id: provInfo[iDProviderName]);
      var val = provider?.getEntity()?.value[provInfo[iDBind]];
      if (val == null && provider != null) {
        if (mode == ModeRendering.design) {
          var nameAttr = provider.getAttrName(provInfo[iDBind]);
          return '[@$nameAttr]';
        } else {
          return '';
        }
      } else {
        return val?.toString() ?? 'no map';
      }
    } else {
      CWRepository? provider = CWRepository.of(ctx);
      return provider?.getStringValueOf(ctx, iDBind) ?? 'no map';
    }
  }

  bool getMapBool() {
    CWRepository? provider = CWRepository.of(ctx);
    return provider?.getBoolValueOf(ctx, iDBind) ?? false;
  }

  double? getMapDouble() {
    CWRepository? provider = CWRepository.of(ctx);
    return provider?.getDoubleValueOf(ctx, iDBind);
  }

  Map<String, dynamic>? getMapOne(String id) {
    CWRepository? provider = CWRepository.of(ctx);
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
    CWRepository? provider = CWRepository.of(ctx);
    if (provider != null) {
      return await provider.getItemsCount(ctx);
    }
    return -1;
  }

  int getItemsCountSync(CWWidgetCtx ctx) {
    CWRepository? provider = CWRepository.of(ctx);
    if (provider != null) {
      return provider.getItemsCountSync();
    }
    return -1;
  }

  void setProviderDataOK(CWRepository? provider, int ok) {
    if (provider != null &&
        provider.loader != null &&
        !provider.loader!.isSync()) {
      CoreGlobalCache.setCache(provider, ok);
    }
  }

  dynamic initFutureDataOrNot(CWRepository? provider, CWWidgetCtx ctx) {
    bool isSync = true;
    if (provider != null &&
        provider.loader != null &&
        !provider.loader!.isSync()) {
      isSync = false;
      int cacheNbRow = CoreGlobalCache.getCacheNbRow(provider);
      if (cacheNbRow != -1) {
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

abstract class CWWidgetWithChild extends CWWidget {
  const CWWidgetWithChild({super.key, required super.ctx});
  int getDefChild(String id);

  int getNbChild(String id, int def) {
    return ctx.designEntity?.getInt(id, def) ?? def;
  }

  List<CWWidget> getChildren() {
    List<CWWidget> children = [];
    for (var p in ctx.factory.mapXidByPath.entries) {
      if (p.key.startsWith(ctx.pathWidget) && p.key != ctx.pathWidget) {
        children.add(ctx.factory.mapWidgetByXid[p.value]!);
      }
    }
    return children;
  }
}

abstract class CWWidgetMapLabel extends CWWidgetMapValue {
  const CWWidgetMapLabel({super.key, required super.ctx});
}

mixin CWWidgetInheritRow {
  InheritedRow? getRowState(BuildContext context) {
    InheritedRow? row = context.getInheritedWidgetOfExactType<InheritedRow>();
    return row;
  }

  void setRepositoryDisplayRow(InheritedRow? row) {
    var provider = row?.getCWRepository();
    if (provider != null) {
      if (row != null) {
        //print("row.index = ${row.index}");
        provider.displayRenderingMode = DisplayRenderingMode.displayed;
        provider.getData().idxDisplayed = row.index!;
      }
    }
  }
}

abstract class CWWidgetMapValue extends CWWidget
    with CWWidgetProvider, CWWidgetInheritRow {
  const CWWidgetMapValue({super.key, required super.ctx});

  @override
  CWRepository? getRepository() {
    var bind =
        ctx.designEntity?.getOne(this is CWWidgetMapLabel ? '@label' : '@bind');
    if (bind != null) {
      return CWRepository.of(ctx, id: bind[iDProviderName]);
    }
    return CWRepository.of(ctx);
  }

  CWRepository? getProvider({Map<String, dynamic>? provInfo}) {
    if (provInfo != null) {
      return CWRepository.of(ctx, id: provInfo[iDProviderName]);
    } else {
      return CWRepository.of(ctx);
    }
  }

  void setValue(dynamic val,
      {InheritedRow? row, Map<String, dynamic>? provInfo}) {
    String attr = provInfo?[iDBind] ?? ctx.designEntity!.getString(iDBind);
    CWRepository? provider = getProvider(provInfo: provInfo);

    if (provider != null) {
      if (row != null) {
        provider.displayRenderingMode = DisplayRenderingMode.displayed;
      } else {
        provider.displayRenderingMode = DisplayRenderingMode.selected;
      }

      CWWidgetEvent ctxWE = CWWidgetEvent();
      ctxWE.action = CWRepositoryAction.onValueChanged.toString();
      ctxWE.provider = provider;
      ctxWE.payload = null;
      ctxWE.loader = ctx.loader;
      provider.setValueOf(ctx, ctxWE, attr, val);
    }
  }

  void doValidateEntity({InheritedRow? row, Map<String, dynamic>? provInfo}) {
    CWRepository? provider = getProvider(provInfo: provInfo);

    if (provider != null) {
      CWWidgetEvent ctxWE = CWWidgetEvent();
      ctxWE.action = CWRepositoryAction.onValidateEntity.toString();
      ctxWE.provider = provider;
      ctxWE.payload = row;
      ctxWE.loader = ctx.loader;
      provider.doAction(ctx, ctxWE, CWRepositoryAction.onValidateEntity);
    }
  }
}

abstract class CWWidgetMapRepository extends CWWidget with CWWidgetProvider {
  const CWWidgetMapRepository({super.key, required super.ctx});

  void setDisplayedIdx(int idx) {
    CWRepository? provider = CWRepository.of(ctx);
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
  StateCW? state;
  CWWidgetInfoSelector infoSelector = CWWidgetInfoSelector();

  WidgetFactoryEventHandler get factory {
    return loader.factory;
  }

  ModeRendering get modeRendering {
    return loader.mode;
  }

  Key? getContentKey(bool padding) {
    var k = getKey();
    if (padding) infoSelector.withPadding = true;
    if (k is GlobalKey) infoSelector.contentKey = k;
    return k;
  }

  Key? getKey() {
    //TODO a retirer customAlphabet  mais bug affichage des attributs
    return modeRendering == ModeRendering.design
        ? GlobalKey(debugLabel: xid)
        : ValueKey('$xid${customAlphabet('1234567890abcdef', 10)}');
  }

  Key? getSlotKey(String prefix, String change) {
    return modeRendering == ModeRendering.design
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

  // reaffect le inSlot aprés un ajout de cmp
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

  bool isSelectedSince(int delay) {
    return CoreDesignerSelector.of().isSelectedWidgetSince(this, delay);
  }

  CWWidget? getWidgetInSlot() {
    final String childXid = factory.mapChildXidByXid[xid] ?? '';
    return factory.mapWidgetByXid[childXid];
  }

  CWWidget? findWidgetInSlot(id) {
    final String childXid = factory.mapChildXidByXid[id] ?? '';
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
  CWRepository? provider;
  CWAppLoaderCtx? loader;
  dynamic ret;
  String? retAction;
}
