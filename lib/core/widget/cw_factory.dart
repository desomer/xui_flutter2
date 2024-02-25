import 'package:xui_flutter/widget/cw_action.dart';
import 'package:xui_flutter/widget/cw_array.dart';
import 'package:xui_flutter/widget/cw_loader.dart';
import 'package:xui_flutter/widget/cw_page.dart';
import 'package:xui_flutter/widget/cw_selector.dart';
import 'package:xui_flutter/widget/cw_switch.dart';
import 'package:xui_flutter/widget/cw_text.dart';
import 'package:xui_flutter/widget/cw_textfield.dart';

import 'cw_core_loader.dart';
import '../../widget/cw_container.dart';
import '../../widget/cw_card.dart';
import '../../widget/cw_dropdown.dart';
import '../../widget/cw_expand_panel.dart';
import '../data/core_data.dart';
import '../data/core_event.dart';
import '../../widget/cw_container_form.dart';
import '../../widget/cw_app.dart';
import '../../widget/cw_toogle.dart';
import '../../widget/cw_list.dart';
import '../../widget/cw_tab.dart';
import '../data/core_repository.dart';
import 'cw_core_widget.dart';

class CWWidgetCollectionBuilder {
  static String getWidgetName(String type) {
    return type.substring(2);
  }

  CWWidgetCollectionBuilder() {
    _initCollection();
    _initWidget();
  }

  final CoreDataCollection collection = CoreDataCollection();

  /////////////////////////////////////////////////////////////////////////
  void _initWidget() {
    CWApp.initFactory(this);
    CWTab.initFactory(this);
    CWTextfield.initFactory(this);

    addWidget('CWSwitch',
            (CWWidgetCtx ctx) => CWSwitch(key: ctx.getKey(), ctx: ctx))
        .addAttr('label', CDAttributType.text)
        .addAttr(iDBind, CDAttributType.text)
        .addAttr(iDProviderName, CDAttributType.text);

    CWLoader.initFactory(this);
    CWExpandPanel.initFactory(this);
    CWText.initFactory(this);
    CWColumn.initFactory(this);
    CWForm.initFactory(this);
    CWRow.initFactory(this);
    CWList.initFactory(this);
    CWArray.initFactory(this);
    CWActionLink.initFactory(this);
    CWSelector.initFactory(this);
    CWCard.initFactory(this);
    CWToogle.initFactory(this);
    CWDropdown.initFactory(this);
  }

  /////////////////////////////////////////////////////////////////////////
  void _initCollection() {
    collection
        .addObject('CWFactory')
        .addAttr('child', CDAttributType.one, tname: 'CWChild')
        .addAttr('designs', CDAttributType.many, tname: 'CWDesign');

    collection
        .addObject('CWDesign')
        .addAttr('xid', CDAttributType.text)
        .addAttr('child', CDAttributType.one, tname: 'CWChild')
        .addAttr('properties', CDAttributType.one, tname: 'CWWidget')
        .addAttr('constraint', CDAttributType.one, tname: 'CWWidget');

    collection
        .addObject('CWChild')
        .addAttr('xid', CDAttributType.text)
        .addAttr('implement', CDAttributType.text);

    addWidget('CWProvider', (CWWidgetCtx ctx) {
      return CWRepositoryCtx(ctx);
    })
        .addAttr('type', CDAttributType.text)
        .addAttr(iDProviderName, CDAttributType.text);

    addWidget('CWPage', (CWWidgetCtx ctx) {
      return CWPageCtx(ctx);
    });
  }

  CoreDataObjectBuilder addWidget(String type, Function f) {
    return collection
        .addObject(type, label: getWidgetName(type))
        .addObjectAction('BuildWidget', f);
  }
}

class WidgetDesign {
  WidgetDesign(this.path, this.prop);

  String path;
  CoreDataEntity? prop;
}

enum ModeParseSlot 
{
  build,
  create,
  move,
  save
}

class WidgetFactoryEventHandler extends CoreBrowseEventHandler {
  WidgetFactoryEventHandler(this.loader);
  CWAppLoaderCtx loader;

  Map<String, CWWidget> mapWidgetByXid = <String, CWWidget>{};
  Map<String, CWWidgetVirtual> mapWidgetVirtualByXid =
      <String, CWWidgetVirtual>{};
  //sauvegarde temporaire avec build
  Map<String, WidgetDesign> mapDesignByXid = <String, WidgetDesign>{};

  Map<String, CWWidgetCtx> mapConstraintByXid = <String, CWWidgetCtx>{};
  Map<String, SlotConfig> mapSlotConstraintByPath = <String, SlotConfig>{};

  Map<String, String> mapChildXidByXid = <String, String>{};
  Map<String, String> mapXidByPath = <String, String>{};

  Map<String, CWRepository> mapRepository = <String, CWRepository>{};

  void initSlot(ModeParseSlot mode) {
    final rootWidget = mapWidgetByXid['root']!;
    rootWidget.initSlot('root', mode);
  }

  void disposePath(String path) {
    List<String> xidToDelete = [];
    List<String> xidSlotToDelete = [];
    List<String> pathToDelete = [];
    for (var p in mapXidByPath.entries) {
      if (p.key.startsWith(path)) {
        pathToDelete.add(p.key);
        xidToDelete.add(p.value);
        mapWidgetByXid.remove(p.value);
        mapSlotConstraintByPath.remove(p.key);
        mapConstraintByXid.remove(p.value);
      }
    }
    for (var c in mapChildXidByXid.entries) {
      if (xidToDelete.contains(c.value)) {
        xidSlotToDelete.add(c.key);
      }
    }
    for (var element in xidSlotToDelete) {
      mapChildXidByXid.remove(element);
    }
    for (var element in pathToDelete) {
      mapXidByPath.remove(element);
    }
    List designToRemove = [];
    List designs = loader.entityCWFactory.value['designs'] ?? [];
    for (var d in designs) {
      if (xidToDelete.contains(d['xid']) ||
          xidSlotToDelete.contains(d['xid'])) {
        designToRemove.add(d);
      }
    }
    for (var element in designToRemove) {
      designs.remove(element);
    }
  }

  // void doRepaintByXid(String? xid) {
  //   CWWidget? widgetRepaint = mapWidgetByXid[xid];
  //   // ignore: invalid_use_of_protected_member
  //   (widgetRepaint?.key as GlobalKey).currentState?.setState(() {});
  // }

  // void doRepaintByPath(String? path) {
  //   String? xid = mapXidByPath[path];
  //   CWWidget? widgetRepaint = mapWidgetByXid[xid];
  //   // ignore: invalid_use_of_protected_member
  //   (widgetRepaint?.key as GlobalKey).currentState?.setState(() {});
  // }

  @override
  void process(CoreDataCtx ctx) {
    // super.process(ctx);
    if (ctx.event!.action.startsWith('browserObjectEnd')) {
      // final String id = ctx.getPathData();
      // final String idParent = ctx.getParentPathData();
      // debugPrint(
      //     'WidgetFactoryEventHandler id=<$id> p=<$idParent> t=${ctx.event!.builder.name}  o=${ctx.event!.entity}');

      if (ctx.event!.builder.name == 'CWChild') {
        final String xid = ctx.event!.entity.getString('xid', def: '')!;
        if (mapWidgetByXid[xid] == null) {
          // ne recreer pas 2 fois un cmp si plusieur getWidget
          final String implement =
              ctx.event!.entity.getString('implement', def: '')!;
          final CWWidgetCtx ctxW = CWWidgetCtx(xid, loader, xid);
          ctx.payload = ctxW;
          final CoreDataObjectBuilder wid =
              loader.collectionWidget.getClass(implement)!;
          final dynamic widg = wid.actions['BuildWidget']?.execute(ctx);

          if (widg is CWWidget) {
            mapWidgetByXid[xid] = widg;
            widg.ctx.pathDataCreate = ctx.getPathData();
          }
          if (widg is CWWidgetVirtual) {
            mapWidgetVirtualByXid[xid] = widg;
            widg.ctx.pathDataCreate = ctx.getPathData();
          }

          WidgetDesign? design = mapDesignByXid[xid];
          if (design != null) {
            mapDesignByXid.remove(xid);
            initWidgetDesign(xid, design.path, design.prop);
          }
        }
        //debugPrint(' $xid >>>>>>>>>>>>>>> ${mapWidgetByXid[xid]!}');
      }
      if (ctx.event!.builder.name == 'CWDesign') {
        final String xid = ctx.event!.entity.getString('xid', def: '')!;
        String path = ctx.getPathData();
        final CoreDataEntity? prop = ctx.event!.entity
            .getOneEntity(loader.collectionWidget, 'properties');

        if (mapWidgetByXid[xid] == null && mapWidgetVirtualByXid[xid] == null) {
          mapDesignByXid[xid] = WidgetDesign(path, prop);
        } else {
          initWidgetDesign(xid, path, prop);
        }

        ////////////////////////////  constraint ///////////////////////////////
        final CoreDataEntity? constraint = ctx.event!.entity
            .getOneEntity(loader.collectionWidget, 'constraint');
        if (constraint != null) {
          CWWidgetCtx ctxConstraint = CWWidgetCtx(xid, loader, '?');
          ctxConstraint.designEntity = constraint;
          ctxConstraint.pathDataDesign = ctx.getPathData();
          mapConstraintByXid[xid] = ctxConstraint;
        }

        ////////////////////////////  child   //////////////////////////////////
        final CoreDataEntity? child =
            ctx.event!.entity.getOneEntity(loader.collectionWidget, 'child');
        if (child != null) {
          mapChildXidByXid[xid] = child.getString('xid', def: '')!;
        }
      }
    }
  }

  // affecte le design du composant  
  void initWidgetDesign(String xid, String path, CoreDataEntity? prop) async {
    CWWidget? wid = mapWidgetByXid[xid];
    CWWidgetVirtual? widVir = mapWidgetVirtualByXid[xid];



    if (prop != null) {
      wid?.ctx.pathDataDesign = path;
      widVir?.ctx.pathDataDesign = path;

      wid?.ctx.designEntity = prop;
      widVir?.ctx.designEntity = prop;

      if (wid != null) {
        CWWidgetEvent ctxWE = CWWidgetEvent();
        ctxWE.action = CWRepositoryAction.onFactoryMountWidget.name;
        ctxWE.payload = mapWidgetByXid[xid];

        mapRepository[mapRepository.keys.firstOrNull]
            ?.getData()
            .actions[CWRepositoryAction.onFactoryMountWidget]
            ?.first
            .execute(wid.ctx, ctxWE);
      }
    }
  }
}
