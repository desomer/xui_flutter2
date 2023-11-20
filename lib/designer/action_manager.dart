import 'package:nanoid/nanoid.dart';
import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/designer.dart';
import 'package:xui_flutter/designer/selector_manager.dart';
import 'package:xui_flutter/designer/designer_selector_component.dart';

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

  void doMoveWidget(CWWidget wid, CWWidgetCtx toCtxSlot)
  {
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
      CoreDesigner.emit(CDDesignEvent.reselect, null);
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
}
