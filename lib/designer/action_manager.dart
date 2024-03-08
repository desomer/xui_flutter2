import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';
import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/core/widget/cw_factory.dart';
import 'package:xui_flutter/designer/designer.dart';
import 'package:xui_flutter/designer/selector_manager.dart';
import 'package:xui_flutter/designer/designer_selector_component.dart';

import '../core/widget/cw_core_drag.dart';
import '../core/widget/cw_core_loader.dart';
import 'builder/prop_builder.dart';
import 'dart:convert';

class DesignActionManager {
  void doDelete() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedWidgetContext();
    if (ctx != null) {
      _doDeleteWidget(ctx);
    } else {
      CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
      SlotAction? slotAction = ctx?.inSlot?.slotAction;
      if (slotAction != null) {
        slotAction.doDelete(ctx!);
      } else {
        print('no delete strategy');
      }
    }
  }

  void addBottom() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      slotAction.addBottom(ctx!);
    } else {
      debugPrint('no slotAction');
    }
  }

  void moveTop() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      slotAction.moveTop(ctx!);
    } else {
      debugPrint('no slotAction');
    }
  }

  void moveBottom() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      slotAction.moveBottom(ctx!);
    }
  }

  void addTop() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      slotAction.addTop(ctx!);
    } else {
      debugPrint('no slotAction');
    }
  }

  void addRight() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      slotAction.addRight(ctx!);
    } else {
      debugPrint('no slotAction');
    }
  }

  void moveRight() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      slotAction.moveRight(ctx!);
    } else {
      debugPrint('no slotAction');
    }
  }

  void moveLeft() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      slotAction.moveLeft(ctx!);
    } else {
      debugPrint('no slotAction');
    }
  }

  void addLeft() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      slotAction.addLeft(ctx!);
    } else {
      debugPrint('no slotAction');
    }
  }

  //////////////////////////////////////////////////////////////////////////////

  void doCloneInSlot(CWWidgetCtx fromCtx, CWWidgetCtx toCtxSlot) {
    var aLoader = CoreDesigner.ofLoader().ctxLoader;
    CoreDataPath path = aLoader.entityCWFactory
        .getPath(aLoader.collectionWidget, fromCtx.pathDataCreate!);

    //print(path);
    String impl = path.entities.last.value['implement'];

    String newXid = impl + customAlphabet('1234567890abcdef', 10);

    String pathCreate =
        CoreDesigner.ofLoader().addChild(toCtxSlot.xid, newXid, impl);

    final CWWidgetCtx ctxW = CWWidgetCtx(
        newXid, toCtxSlot.loader, '${toCtxSlot.pathWidget}.${toCtxSlot.xid}');

    var newWidget = _createWidget(ctxW, impl);

    newWidget.ctx.pathDataCreate = pathCreate;
    toCtxSlot.factory.mapChildXidByXid[toCtxSlot.xid] = newXid;

    final rootWidget = toCtxSlot.factory.mapWidgetByXid['root']!;
    rootWidget.initSlot('root', ModeParseSlot.create);

    if (fromCtx.designEntity != null) {
      CoreDataEntity prop = PropBuilder.preparePropChange(
          ctxW.loader, DesignCtx().forDesign(ctxW));
      prop.value.addAll(jsonDecode( jsonEncode(fromCtx.designEntity!.value)));
    }

    // repaint le parent du slot
    _repaintPath(toCtxSlot, select: true);
  }

  void doMoveWidget(CWWidget wid, CWWidgetCtx toCtxSlot) {
    var aLoader = CoreDesigner.ofLoader().ctxLoader;
    CoreDataPath path = aLoader.entityCWFactory
        .getPath(aLoader.collectionWidget, wid.ctx.pathDataCreate!);
    CoreDataEntity cwchild = path.remove(false);
    _move(toCtxSlot, wid, cwchild, toCtxSlot);
  }

  void doMoveInSlot(CWWidgetCtx ctxSlot, CWWidgetCtx toCtxSlot,
      {bool repaint = true}) {
    CWWidget? child = ctxSlot.getWidgetInSlot();
    if (child != null) {
      CoreDataEntity cwchild = _delete(child, ctxSlot, false);

      _move(toCtxSlot, child, cwchild, ctxSlot);

      // repaint le parent
      _repaintPath(ctxSlot);
      _repaintPath(toCtxSlot, select: true);
    }
  }

  void doWrapWith(CWWidgetCtx ctx, String implem, String slotName) {
    CWWidget root = ctx.getParentCWWidget() as CWWidget;

    String path = ctx.pathWidget;
    CWWidget? last = ctx.findWidgetByPath(path);

    CWWidget colWidget = DesignActionManager()
        .doCreate(ctx, ComponentDesc('', Icons.abc, implem));

    if (last != null) {
      String pathTo = '${colWidget.ctx.pathWidget}.$slotName';

      Future.delayed(const Duration(milliseconds: 100), () {
        var v2 = ctx.findSlotByPath(pathTo);
        DesignActionManager().doMoveWidget(last, v2!.ctx);
        root.repaint();
        // Future.delayed(const Duration(milliseconds: 100), () {
        //   // CoreDesigner.emit(CDDesignEvent.select, toCtxSlot);
        // });
      });
    }
  }

  void doSwap(CWWidgetCtx ctxSlot, CWWidgetCtx toCtxSlot,
      {bool repaint = true}) {
    CWWidget? child = ctxSlot.getWidgetInSlot();
    CWWidget? child2 = toCtxSlot.getWidgetInSlot();
    CoreDataEntity? cwchild;
    CoreDataEntity? cwchild2;

    if (child != null) {
      cwchild = _delete(child, ctxSlot, false);
    }
    if (child2 != null) {
      cwchild2 = _delete(child2, toCtxSlot, false);
    }

    if (cwchild != null) {
      _move(toCtxSlot, child!, cwchild, ctxSlot);
    }

    if (cwchild2 != null) {
      _move(ctxSlot, child2!, cwchild2, toCtxSlot);
    }

    _repaintPath(ctxSlot);
    _repaintPath(toCtxSlot, select: true);
  }

  CWWidget doCreate(CWWidgetCtx toCtxSlot, ComponentDesc desc) {
    var cmp = _doCreate(toCtxSlot, desc);

    final rootWidget = toCtxSlot.factory.mapWidgetByXid['root']!;
    rootWidget.initSlot('root', ModeParseSlot.create);

    // repaint le parent du slot
    _repaintPath(toCtxSlot, select: true);

    return cmp;
  }

  void doPageAction(CWWidgetCtx toWidget, DragPageCtx query) {
    CoreDataEntity prop = PropBuilder.preparePropChange(
        toWidget.loader, DesignCtx().forDesign(toWidget));
    prop.value['_idAction_'] = '${query.page.value['route']}@router';
  }

  void doReposAction(CWWidgetCtx toWidget, DragRepositoryEventCtx event) {
    CoreDataEntity prop = PropBuilder.preparePropChange(
        toWidget.loader, DesignCtx().forDesign(toWidget));
    prop.value['_idAction_'] = event.id;
  }

  ///////////////////////////////////////////////////////////////////////////////////////
  
  void _repaintPath(CWWidgetCtx ctx, {bool? select}) {
    CWWidget? w = CoreDesigner.ofView()
        .getWidgetByPath(CWWidgetCtx.getParentPathFrom(ctx.pathWidget));
    w?.repaint();

    if (select ?? false) {
      Future.delayed(const Duration(milliseconds: 100), () {
        CoreDesigner.emit(CDDesignEvent.select, ctx);
      });
    }
  }

  void _doDeleteWidget(CWWidgetCtx ctx) {
    CWWidget? child = ctx.getCWWidget();
    if (child != null) {
      CWSlot? slot = ctx.getSlot();
      _delete(child, ctx, true);

      ctx.factory.disposePath(ctx.pathWidget);

      // repaint le parent
      _repaintPath(slot!.ctx, select: true);
    }
  }

  CWWidget _doCreate(CWWidgetCtx toCtxSlot, ComponentDesc desc) {
    String newXid = desc.impl + customAlphabet('1234567890abcdef', 10);

    String pathCreate =
        CoreDesigner.ofLoader().addChild(toCtxSlot.xid, newXid, desc.impl);

    final CWWidgetCtx ctxW = CWWidgetCtx(
        newXid, toCtxSlot.loader, '${toCtxSlot.pathWidget}.${toCtxSlot.xid}');

    var newWidget = _createWidget(ctxW, desc.impl);

    newWidget.ctx.pathDataCreate = pathCreate;
    toCtxSlot.factory.mapChildXidByXid[toCtxSlot.xid] = newXid;

    return newWidget;
  }

  void _move(CWWidgetCtx toCtxSlot, CWWidget child, CoreDataEntity cwchild,
      CWWidgetCtx ctxBuild) {
    String pathCreate = CoreDesigner.ofLoader()
        .addChild(toCtxSlot.xid, child.ctx.xid, cwchild.value['implement']);

    final CWWidgetCtx ctxW = CWWidgetCtx(child.ctx.xid, ctxBuild.loader,
        '${toCtxSlot.pathWidget}.${toCtxSlot.xid}');

    //recrer un composant
    var newWidget = _createWidget(ctxW, cwchild.value['implement'],
        designEntity: child.ctx.designEntity);

    newWidget.ctx.pathDataCreate = pathCreate;
    newWidget.ctx.pathDataDesign = child.ctx.pathDataDesign;
    ctxBuild.factory.mapChildXidByXid[toCtxSlot.xid] = child.ctx.xid;

    // suppression des path
    List<String> pathToDelete = [];
    for (var p in ctxBuild.factory.mapXidByPath.entries) {
      if (p.key.startsWith(child.ctx.pathWidget)) {
        pathToDelete.add(p.key);
        ctxBuild.factory.mapSlotConstraintByPath.remove(p.key);
      }
    }

    for (var element in pathToDelete) {
      ctxBuild.factory.mapXidByPath.remove(element);
    }
    // réaffecte les pathWidget
    final rootWidget = ctxBuild.factory.mapWidgetByXid['root']!;
    rootWidget.initSlot('root', ModeParseSlot.move);
  }

  CWWidget _createWidget(CWWidgetCtx ctxW, String impl,
      {CoreDataEntity? designEntity}) {
    CoreDataCtx ctx = CoreDataCtx();
    ctx.payload = ctxW;
    final CoreDataObjectBuilder wid =
        ctxW.loader.collectionWidget.getClass(impl)!;
    final CWWidget newWidget =
        wid.actions['BuildWidget']!.execute(ctx) as CWWidget;

    newWidget.ctx.designEntity = designEntity;

    ctxW.factory.mapWidgetByXid[newWidget.ctx.xid] = newWidget;

    return newWidget;
  }

  CoreDataEntity _delete(CWWidget child, CWWidgetCtx ctxSlot, bool withDesign) {
    var aLoader = CoreDesigner.ofLoader().ctxLoader;

    String pathStr = child.ctx.pathDataCreate!
        .substring(0, child.ctx.pathDataCreate!.length - '.child'.length);
    CoreDataPath path = aLoader.entityCWFactory
        .getPath(aLoader.collectionWidget, child.ctx.pathDataCreate!);
    CoreDataEntity cwchild = path.remove(false);
    CoreDataPath pathDesign =
        aLoader.entityCWFactory.getPath(aLoader.collectionWidget, pathStr);
    pathDesign.remove(true);

    if (withDesign) {
      List designToRemove = [];
      List designs = aLoader.entityCWFactory.value['designs'] ?? [];
      for (var d in designs) {
        if (child.ctx.xid.contains(d['xid'])) {
          designToRemove.add(d);
        }
      }
      for (var element in designToRemove) {
        designs.remove(element);
      }
    }

    ctxSlot.factory.mapWidgetByXid.remove(child.ctx.xid);
    ctxSlot.factory.mapChildXidByXid.remove(ctxSlot.xid);
    ctxSlot.factory.mapXidByPath.remove(ctxSlot.pathWidget);
    return cwchild;
  }

  ////////////////////////////////////////////////////////////////////////
  bool doDeleteSlot(CWWidgetCtx ctx, DesignActionConfig config) {
    int i = ctx.pathWidget.lastIndexOf('.${config.tag}');
    int idxChild =
        int.parse(ctx.pathWidget.substring(i + config.tag.length + 1));
    CWWidgetWithChild parent = ctx.getParentCWWidget() as CWWidgetWithChild;

    int nbChild = 0;
    if (config.ctxConstraint == null) {
      nbChild = parent.getNbChild(
          config.countTag, parent.getDefChild(config.countTag));
      CoreDataEntity prop = PropBuilder.preparePropChange(
          ctx.loader, DesignCtx().forDesign(parent.ctx));
      prop.value[config.countTag] = nbChild - 1;
    } else {
      nbChild = config.ctxConstraint?.designEntity?.value[config.countTag] ?? 1;

      var aCtxConstraint = DesignCtx().forConstraint(config.ctxConstraint!);
      CoreDataEntity prop =
          PropBuilder.preparePropChange(ctx.loader, aCtxConstraint);
      prop.value[config.countTag] = nbChild - 1;
      if (prop.value[config.countTag] < config.minChild) {
        prop.value[config.countTag] = config.minChild;
      }
    }

    if (idxChild < nbChild - 1) {
      for (var i = idxChild + 1; i < nbChild; i++) {
        debugPrint('move $i');
        String path = '${parent.ctx.pathWidget}.${config.tag}$i';
        String pathTo = '${parent.ctx.pathWidget}.${config.tag}${i - 1}';
        var v = ctx.findWidgetByPath(path);
        var v2 = ctx.findSlotByPath(pathTo);
        if (v != null) {
          DesignActionManager().doMoveInSlot(v.ctx.getSlot()!.ctx, v2!.ctx);
        }
      }
    }
    parent
      ..repaint()
      ..select();
    return true;
  }

  bool addBeforeOrAfter(CWWidgetCtx ctx, DesignActionConfig config) {
    int ic = ctx.pathWidget.lastIndexOf('.${config.tag}');
    int idxChild =
        int.parse(ctx.pathWidget.substring(ic + config.tag.length + 1));

    int nbChild = 0;
    CWWidgetWithChild parent = ctx.getParentCWWidget() as CWWidgetWithChild;

    if (config.ctxConstraint == null) {
      nbChild = parent.getNbChild(
          config.countTag, parent.getDefChild(config.countTag));

      CoreDataEntity prop = PropBuilder.preparePropChange(
          ctx.loader, DesignCtx().forDesign(parent.ctx));
      prop.value[config.countTag] = nbChild + 1;
    } else {
      nbChild = config.ctxConstraint?.designEntity?.value[config.countTag] ?? 1;

      var aCtxConstraint = DesignCtx().forConstraint(config.ctxConstraint!);
      CoreDataEntity prop =
          PropBuilder.preparePropChange(ctx.loader, aCtxConstraint);
      prop.value[config.countTag] = nbChild + 1;
    }

    parent
      ..repaint()
      ..select();

    // delay pour avoir les nouveaux slot dans les findSlotByPath
    Future.delayed(const Duration(milliseconds: 1), () {
      if (idxChild < nbChild - 1 + (config.before ? 1 : 0)) {
        for (var i = nbChild - 1;
            i > (idxChild - (config.before ? 1 : 0));
            i--) {
          debugPrint('move $i');
          String path = '${parent.ctx.pathWidget}.${config.tag}$i';
          String pathTo = '${parent.ctx.pathWidget}.${config.tag}${i + 1}';
          var v = ctx.findWidgetByPath(path);
          var v2 = ctx.findSlotByPath(pathTo);
          if (v != null && v2 != null) {
            DesignActionManager().doMoveInSlot(v.ctx.getSlot()!.ctx, v2.ctx);
          }
        }
      }
    });
    return true;
  }

  bool moveBeforeOrAfter(CWWidgetCtx ctx, DesignActionConfig config) {
    int ic = ctx.pathWidget.lastIndexOf('.${config.tag}');

    int idxChild =
        int.parse(ctx.pathWidget.substring(ic + config.tag.length + 1));
    CWWidgetWithChild parent = ctx.getParentCWWidget() as CWWidgetWithChild;

    int nbChild = 0;
    if (config.ctxConstraint == null) {
      nbChild = parent.getNbChild(
          config.countTag, parent.getDefChild(config.countTag));
    } else {
      nbChild = config.ctxConstraint?.designEntity?.value[config.countTag] ?? 1;
    }

    var boolBottom = config.before == false && (idxChild < nbChild - 1);
    var boolTop = config.before == true && (idxChild > 0);

    if (boolBottom || boolTop) {
      debugPrint('move $idxChild');
      String path = '${parent.ctx.pathWidget}.${config.tag}$idxChild';
      String pathTo =
          '${parent.ctx.pathWidget}.${config.tag}${idxChild + 1 + (config.before ? -2 : 0)}';
      var v = ctx.findWidgetByPath(path);
      var v2 = ctx.findSlotByPath(pathTo);
      if (v != null) {
        DesignActionManager().doSwap(v.ctx.getSlot()!.ctx, v2!.ctx);
      }
    }

    return true;
  }

  //////////////////////////////////////////////
  bool canMoveBottom() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      return slotAction.canMoveBottom();
    } else {
      return false;
    }
  }

  bool canMoveTop() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      return slotAction.canMoveTop();
    } else {
      return false;
    }
  }

  bool canMoveLeft() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      return slotAction.canMoveLeft();
    } else {
      return false;
    }
  }

  bool canMoveRight() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      return slotAction.canMoveRight();
    } else {
      return false;
    }
  }

  //////////////////////////////////////////////

  bool canAddBottom() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      return slotAction.canAddBottom();
    } else {
      return false;
    }
  }

  bool canAddTop() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      return slotAction.canAddTop();
    } else {
      return false;
    }
  }

  bool canAddLeft() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      return slotAction.canAddLeft();
    } else {
      return false;
    }
  }

  bool canAddRight() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      return slotAction.canAddRight();
    } else {
      return false;
    }
  }
}

class DesignActionConfig {
  DesignActionConfig(this.tag, this.countTag, this.before,
      {this.ctxConstraint});

  final String tag;
  final bool before;
  final String countTag;
  CWWidgetCtx? ctxConstraint;
  int minChild = 1;
}
