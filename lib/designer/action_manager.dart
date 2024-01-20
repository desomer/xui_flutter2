import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';
import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/designer.dart';
import 'package:xui_flutter/designer/selector_manager.dart';
import 'package:xui_flutter/designer/designer_selector_component.dart';

import '../core/widget/cw_core_loader.dart';
import 'builder/prop_builder.dart';

class DragCtx {
  DragCtx(this.component, this.srcWidgetCtx);

  ComponentDesc? component;
  CWWidgetCtx? srcWidgetCtx;
}

class DesignActionManager {
  void doDelete() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedWidgetContext();
    if (ctx != null) {
      DesignActionManager()._doDeleteWidget(ctx);
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
    }
  }

  void moveTop() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      slotAction.moveTop(ctx!);
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
    }
  }

  void addRight() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      slotAction.addRight(ctx!);
    }
  }

  void moveRight() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      slotAction.moveRight(ctx!);
    }
  }

  void moveLeft() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      slotAction.moveLeft(ctx!);
    }
  }

  void addLeft() {
    CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
    SlotAction? slotAction = ctx?.inSlot?.slotAction;
    if (slotAction != null) {
      slotAction.addLeft(ctx!);
    }
  }

  ///////////////////////////////////////////////////////////////////////////
  void _doDeleteWidget(CWWidgetCtx ctx) {
    CWWidget? child = ctx.getCWWidget();
    if (child != null) {
      CWSlot? slot = ctx.getSlot();
      _delete(child, ctx, true);

      ctx.factory.disposePath(ctx.pathWidget);

      // repaint le parent
      CWWidget? w = CoreDesigner.ofView()
          .getWidgetByPath(CWWidgetCtx.getParentPathFrom(ctx.pathWidget));
      w?.repaint();

      Future.delayed(const Duration(milliseconds: 100), () {
        CoreDesigner.emit(CDDesignEvent.select, slot!.ctx);
      });
    }
  }

  void doMoveWidget(CWWidget wid, CWWidgetCtx toCtxSlot) {
    var aLoader = CoreDesigner.ofLoader().ctxLoader;
    CoreDataPath path = aLoader.entityCWFactory
        .getPath(aLoader.collectionWidget, wid.ctx.pathDataCreate!);
    CoreDataEntity cwchild = path.remove(false);
    _move(toCtxSlot, wid, cwchild, toCtxSlot);
  }

  void doMove(CWWidgetCtx ctxSlot, CWWidgetCtx toCtxSlot,
      {bool repaint = true}) {
    CWWidget? child = ctxSlot.getWidgetInSlot();
    if (child != null) {
      CoreDataEntity cwchild = _delete(child, ctxSlot, false);

      _move(toCtxSlot, child, cwchild, ctxSlot);

      // repaint le parent
      CWWidget? w = CoreDesigner.ofView()
          .getWidgetByPath(CWWidgetCtx.getParentPathFrom(ctxSlot.pathWidget));
      w?.repaint();

      // repaint le parent
      w = CoreDesigner.ofView()
          .getWidgetByPath(CWWidgetCtx.getParentPathFrom(toCtxSlot.pathWidget));
      w?.repaint();

      Future.delayed(const Duration(milliseconds: 100), () {
        CoreDesigner.emit(CDDesignEvent.select, toCtxSlot);
      });
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
        Future.delayed(const Duration(milliseconds: 100), () {
          // CoreDesigner.emit(CDDesignEvent.select, toCtxSlot);
        });
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

    // repaint le parent
    CWWidget? w = CoreDesigner.ofView()
        .getWidgetByPath(CWWidgetCtx.getParentPathFrom(ctxSlot.pathWidget));
    w?.repaint();

    // repaint le parent
    w = CoreDesigner.ofView()
        .getWidgetByPath(CWWidgetCtx.getParentPathFrom(toCtxSlot.pathWidget));
    w?.repaint();

    Future.delayed(const Duration(milliseconds: 100), () {
      CoreDesigner.emit(CDDesignEvent.select, toCtxSlot);
    });
  }

  CWWidget doCreate(CWWidgetCtx toCtxSlot, ComponentDesc desc) {
    var cmp = _doCreate(toCtxSlot, desc);

    final rootWidget = toCtxSlot.factory.mapWidgetByXid['root']!;
    rootWidget.initSlot('root');

    // repaint le parent du slot
    CWWidget? w = CoreDesigner.ofView()
        .getWidgetByPath(CWWidgetCtx.getParentPathFrom(toCtxSlot.pathWidget));
    w?.repaint();

    Future.delayed(const Duration(milliseconds: 100), () {
      CoreDesigner.emit(CDDesignEvent.select, toCtxSlot);
    });

    return cmp;
  }

  ///////////////////////////////////////////////////////////////////////////////////////
  CWWidget _doCreate(CWWidgetCtx toCtxSlot, ComponentDesc desc) {
    String newXid = desc.impl + customAlphabet('1234567890abcdef', 10);

    String pathCreate =
        CoreDesigner.ofLoader().addChild(toCtxSlot.xid, newXid, desc.impl);

    final CWWidgetCtx ctxW = CWWidgetCtx(toCtxSlot.xid, toCtxSlot.loader,
        '${toCtxSlot.pathWidget}.${toCtxSlot.xid}');

    CoreDataCtx ctx = CoreDataCtx();
    ctx.payload = ctxW;
    final CoreDataObjectBuilder wid =
        toCtxSlot.loader.collectionWidget.getClass(desc.impl)!;
    final CWWidget newWidget =
        wid.actions['BuildWidget']!.execute(ctx) as CWWidget;

    toCtxSlot.factory.mapWidgetByXid[newXid] = newWidget;
    newWidget.ctx.pathDataCreate = pathCreate;
    toCtxSlot.factory.mapChildXidByXid[toCtxSlot.xid] = newXid;
    newWidget.ctx.xid = newXid;
    return newWidget;
  }

  void _move(CWWidgetCtx toCtxSlot, CWWidget child, CoreDataEntity cwchild,
      CWWidgetCtx ctxSlot) {
    String pathCreate = CoreDesigner.ofLoader()
        .addChild(toCtxSlot.xid, child.ctx.xid, cwchild.value['implement']);

    final CWWidgetCtx ctxW = CWWidgetCtx(toCtxSlot.xid, ctxSlot.loader,
        '${toCtxSlot.pathWidget}.${toCtxSlot.xid}');

    //recrer un composant
    CoreDataCtx ctx = CoreDataCtx();
    ctx.payload = ctxW;
    final CoreDataObjectBuilder wid =
        ctxSlot.loader.collectionWidget.getClass(cwchild.value['implement'])!;
    final CWWidget newWidget =
        wid.actions['BuildWidget']!.execute(ctx) as CWWidget;

    newWidget.ctx.designEntity = child.ctx.designEntity;
    newWidget.ctx.pathDataDesign = child.ctx.pathDataDesign;

    ctxSlot.factory.mapWidgetByXid[child.ctx.xid] = newWidget;
    newWidget.ctx.pathDataCreate = pathCreate;
    ctxSlot.factory.mapChildXidByXid[toCtxSlot.xid] = child.ctx.xid;
    newWidget.ctx.xid = child.ctx.xid;

    // suppression des path
    List<String> pathToDelete = [];
    for (var p in ctxSlot.factory.mapXidByPath.entries) {
      if (p.key.startsWith(child.ctx.pathWidget)) {
        pathToDelete.add(p.key);
        ctxSlot.factory.mapSlotConstraintByPath.remove(p.key);
      }
    }

    for (var element in pathToDelete) {
      ctxSlot.factory.mapXidByPath.remove(element);
    }
    // réaffecte les pathWidget
    final rootWidget = ctxSlot.factory.mapWidgetByXid['root']!;
    rootWidget.initSlot('root');
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
  bool doDeleteSlot(CWWidgetCtx ctx, String tag, String countTag) {
    int i = ctx.pathWidget.lastIndexOf('.$tag');
    int idxChild = int.parse(ctx.pathWidget.substring(i + tag.length + 1));
    CWWidgetChild parent = ctx.getParentCWWidget() as CWWidgetChild;
    int nbChild = parent.getNbChild(countTag, parent.getDefChild(countTag));

    CoreDataEntity prop = PropBuilder.preparePropChange(
        ctx.loader, DesignCtx().forDesign(parent.ctx));
    prop.value[countTag] = nbChild - 1;

    if (idxChild < nbChild - 1) {
      for (var i = idxChild + 1; i < nbChild; i++) {
        debugPrint('move $i');
        String path = '${parent.ctx.pathWidget}.$tag$i';
        String pathTo = '${parent.ctx.pathWidget}.$tag${i - 1}';
        var v = ctx.findWidgetByPath(path);
        var v2 = ctx.findSlotByPath(pathTo);
        if (v != null) {
          DesignActionManager().doMove(v.ctx.getSlot()!.ctx, v2!.ctx);
        }
      }
    }
    parent
      ..repaint()
      ..select();
    return true;
  }

  bool addBeforeOrAfter(
      CWWidgetCtx ctx, String tag, bool before, String countTag) {
    int ic = ctx.pathWidget.lastIndexOf('.$tag');
    int idxChild = int.parse(ctx.pathWidget.substring(ic + tag.length + 1));
    CWWidgetChild parent = ctx.getParentCWWidget() as CWWidgetChild;
    int nbChild = parent.getNbChild(countTag, parent.getDefChild(countTag));

    CoreDataEntity prop = PropBuilder.preparePropChange(
        ctx.loader, DesignCtx().forDesign(parent.ctx));
    prop.value[countTag] = nbChild + 1;
    parent
      ..repaint()
      ..select();

    // delay pour avoir les nouveaux slot dans les findSlotByPath
    Future.delayed(const Duration(milliseconds: 1), () {
      if (idxChild < nbChild - 1 + (before ? 1 : 0)) {
        for (var i = nbChild - 1; i > (idxChild - (before ? 1 : 0)); i--) {
          debugPrint('move $i');
          String path = '${parent.ctx.pathWidget}.$tag$i';
          String pathTo = '${parent.ctx.pathWidget}.$tag${i + 1}';
          var v = ctx.findWidgetByPath(path);
          var v2 = ctx.findSlotByPath(pathTo);
          if (v != null) {
            DesignActionManager().doMove(v.ctx.getSlot()!.ctx, v2!.ctx);
          }
        }
      }
    });

    return true;
  }

  bool moveBeforeOrAfter(
      CWWidgetCtx ctx, String tag, bool before, String countTag) {
    int ic = ctx.pathWidget.lastIndexOf('.$tag');
    int idxChild = int.parse(ctx.pathWidget.substring(ic + tag.length + 1));
    CWWidgetChild parent = ctx.getParentCWWidget() as CWWidgetChild;
    int nbChild = parent.getNbChild(countTag, parent.getDefChild(countTag));

    var boolBottom = before == false && (idxChild < nbChild - 1);
    var boolTop = before == true && (idxChild > 0);

    if (boolBottom || boolTop) {
      debugPrint('move $idxChild');
      String path = '${parent.ctx.pathWidget}.$tag$idxChild';
      String pathTo =
          '${parent.ctx.pathWidget}.$tag${idxChild + 1 + (before ? -2 : 0)}';
      var v = ctx.findWidgetByPath(path);
      var v2 = ctx.findSlotByPath(pathTo);
      if (v != null) {
        DesignActionManager().doSwap(v.ctx.getSlot()!.ctx, v2!.ctx);
      }
    }
    return true;
  }
}
