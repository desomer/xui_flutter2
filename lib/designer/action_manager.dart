import 'package:nanoid/nanoid.dart';
import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/designer.dart';
import 'package:xui_flutter/designer/widget_component.dart';

class DragCtx {
  DragCtx(this.component, this.srcWidgetCtx);

  ComponentDesc? component;
  CWWidgetCtx? srcWidgetCtx;
}

class DesignActionManager {
  void doDelete(CWWidgetCtx ctx) {
    CWWidget? child = ctx.getCWWidget();
    if (child != null) {
      CWSlot? slot = ctx.getSlot();
      _delete(child, ctx);

      // repaint le parent
      CWWidget? w = CoreDesigner.ofView()
          .getWidgetByPath(CWWidgetCtx.getParentPathFrom(ctx.pathWidget));
      w?.repaint();

      Future.delayed(const Duration(milliseconds: 100), () {
        CoreDesigner.emit(CDDesignEvent.select, slot!.ctx);
      });
    }
  }

  void doMove(CWWidgetCtx ctxSlot, CWWidgetCtx toCtxSlot) {
    CWWidget? child = ctxSlot.getWidgetInSlot();
    if (child != null) {
      CoreDataEntity cwchild = _delete(child, ctxSlot);

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

  void doCreate(CWWidgetCtx toCtxSlot, ComponentDesc desc) {
    _doCreate(toCtxSlot, desc);

    final rootWidget = toCtxSlot.factory.mapWidgetByXid['root']!;
    rootWidget.initSlot('root');

    // repaint le parent du slot
    CWWidget? w = CoreDesigner.ofView()
        .getWidgetByPath(CWWidgetCtx.getParentPathFrom(toCtxSlot.pathWidget));
    w?.repaint();

    Future.delayed(const Duration(milliseconds: 100), () {
      CoreDesigner.emit(CDDesignEvent.reselect, null);
    });
  }

  ///////////////////////////////////////////////////////////////////////////////////////
  void _doCreate(CWWidgetCtx toCtxSlot, ComponentDesc desc) {

    String newXid = desc.impl + customAlphabet('1234567890abcdef', 10);

    String pathCreate = CoreDesigner.ofLoader()
        .addChild(toCtxSlot.xid, newXid, desc.impl);

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
  }

  void _move(CWWidgetCtx toCtxSlot, CWWidget child, CoreDataEntity cwchild,
      CWWidgetCtx ctxSlot) {
    String pathCreate = CoreDesigner.ofLoader()
        .addChild(toCtxSlot.xid, child.ctx.xid, cwchild.value['implement']);

    final CWWidgetCtx ctxW = CWWidgetCtx(toCtxSlot.xid, ctxSlot.loader,
        '${toCtxSlot.pathWidget}.${toCtxSlot.xid}');

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

    final rootWidget = ctxSlot.factory.mapWidgetByXid['root']!;
    rootWidget.initSlot('root');
  }

  CoreDataEntity _delete(CWWidget child, CWWidgetCtx ctxSlot) {
    CoreDataPath path = CoreDesigner.ofLoader().ctxLoader.entityCWFactory.getPath(
        CoreDesigner.ofLoader().ctxLoader.collectionWidget, child.ctx.pathDataCreate!);
    CoreDataEntity cwchild = path.remove();

    ctxSlot.factory.mapWidgetByXid.remove(child.ctx.xid);
    ctxSlot.factory.mapChildXidByXid.remove(ctxSlot.xid);
    ctxSlot.factory.mapXidByPath.remove(ctxSlot.pathWidget);
    return cwchild;
  }
}
