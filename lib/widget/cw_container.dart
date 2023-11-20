import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';
import 'package:xui_flutter/designer/cw_factory.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_future.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/action_manager.dart';
import '../designer/builder/form_builder.dart';
import '../designer/builder/prop_builder.dart';
import '../designer/designer.dart';
import '../designer/designer_selector_query.dart';

abstract class CWContainer extends CWWidget {
  const CWContainer({super.key, required super.ctx});

  int getDefChild();

  int getNbChild(int def) {
    return ctx.designEntity?.getInt('count', def) ?? def;
  }

  bool isFill(bool def) {
    return ctx.designEntity?.getBool('fill', def) ?? def;
  }

  Widget getCell(int i, bool defFill,
      {required bool canFill, bool? canHeight, bool? canWidth}) {
    var slot = CWSlot(
      type: 'body',
      key: GlobalKey(debugLabel: 'slot ${ctx.xid}_$i'),
      ctx: createChildCtx(ctx, 'Cont', i),
      slotAction: SlotContainerAction(),
    );

    CWWidgetCtx? constraint = ctx.factory.mapConstraintByXid[slot.ctx.xid];
    //print("getCell -------- ${slot.ctx.xid} $constraint");

    int flex = constraint?.designEntity?.value['flex'] ?? 1;
    bool loose = constraint?.designEntity?.value['tight/loose'] ?? false;
    int? height = constraint?.designEntity?.value['height'];
    int? width = constraint?.designEntity?.value['width'];

    // var slot2 = IntrinsicHeight(child: slot);

    if (canHeight != true && height != null) {
      constraint?.designEntity?.value.remove('height');
    }
    if (canWidth != true && width != null) {
      constraint?.designEntity?.value.remove('width');
    }

    if (canHeight == true && height != null && height > 5) {
      return SizedBox(height: height.toDouble(), child: slot);
    } else if (canWidth == true && width != null && width > 5) {
      return SizedBox(width: width.toDouble(), child: slot);
    } else if (isFill(defFill) && canFill) {
      return Flexible(
          flex: flex, fit: loose ? FlexFit.loose : FlexFit.tight, child: slot);
    } else {
      return slot;
    }
  }
}

// ignore: must_be_immutable
class CWColumn extends CWContainer {
  CWColumn({super.key, required super.ctx});
  bool isForm = false;

  @override
  State<CWColumn> createState() => CWColumnState();

  @override
  void initSlot(String path) {
    final nb = getNbChild(getDefChild());
    for (int i = 0; i < nb; i++) {
      addSlotPath('$path.Cont$i',
          SlotConfig('${ctx.xid}Cont$i', constraintEntity: 'CWColConstraint'));
    }
  }

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget('CWColumn',
            (CWWidgetCtx ctx) => CWColumn(key: ctx.getKey(), ctx: ctx))
        .addAttr('count', CDAttributType.int)
        .withAction(AttrActionDefault(2))
        .addAttr('fill', CDAttributType.bool)
        .withAction(AttrActionDefault(true));

    c.collection
        .addObject('CWColConstraint')
        .addAttr('flex', CDAttributType.int)
        .addAttr('tight/loose', CDAttributType.bool)
        .addAttr('height', CDAttributType.int);
    // .addAttr('min (ConstrainedBox)', CDAttributType.CDint)
    // .addAttr('max (ConstrainedBox)', CDAttributType.CDint);
    //    .addAttr('% ()', CDAttributType.CDint);
    //.addAttr('Fitted child (FittedBox)', CDAttributType.CDbool);
  }

  @override
  int getDefChild() {
    return isForm ? 0 : 2;
  }
}

class CWColumnState extends StateCW<CWColumn>
    with CWDroppable, CWWidgetProvider {
  @override
  Widget build(BuildContext context) {
    if (widget.isForm) {
      return buildProvider(context);
    } else {
      return getWidget();
    }
  }

  LayoutBuilder getWidget() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
      final List<Widget> listStack = [];
      final List<Widget> listSlot = [];

      final nb = widget.getNbChild(widget.getDefChild());
      for (var i = 0; i < nb; i++) {
        listSlot.add(widget.getCell(i, true,
            canHeight: true, canFill: viewportConstraints.hasBoundedHeight));
      }

      listStack.add(Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: listSlot));

      if (nb == 0) {
        return Column(children: [getDropQuery(100)]);
      }

      return listStack[0];
    });
  }

  double h = 0;
  double hm = 0;
  double wm = 0;

  @override
  void onDragQuery(DragQueryCtx query) async {
    await FormBuilder().createForm(widget, query.query);
    CoreDesigner.of().providerKey.currentState!.setState(() {});
  }

  Widget buildProvider(BuildContext context) {
    var futureData = initFutureDataOrNot(CWProvider.of(widget.ctx), widget.ctx);

    dynamic getContent(int ok) {
      var provider = CWProvider.of(widget.ctx);
      setProviderDataOK(provider, ok);
      return getWidget();
    }

    if (futureData is Future) {
      return CWFutureWidget(
        futureData: futureData,
        getContent: getContent,
        nbCol: 1,
      );
    } else {
      return getContent(futureData as int);
    }
  }
}

////////////////////////////////////////////////////////////////////////
class CWRow extends CWContainer {
  const CWRow({super.key, required super.ctx});

  static void initFactory(CWWidgetCollectionBuilder c) {
    c.collection
            .addObject('CWRowConstraint')
            .addAttr('flex', CDAttributType.int)
            .addAttr('tight/loose', CDAttributType.bool)
            .addAttr('width', CDAttributType.int)
        // .addAttr('min (ConstrainedBox)', CDAttributType.CDint)
        // .addAttr('max (ConstrainedBox)', CDAttributType.CDint)
        // .addAttr('% (FractionallySizedBox)', CDAttributType.CDint)
        // .addAttr('Fitted child (FittedBox)', CDAttributType.CDbool)
        ;

    c
        .addWidget(
            'CWRow', (CWWidgetCtx ctx) => CWRow(key: ctx.getKey(), ctx: ctx))
        .addAttr('count', CDAttributType.int)
        .withAction(AttrActionDefault(3))
        .addAttr('fill', CDAttributType.bool)
        .withAction(AttrActionDefault(true));
  }

  @override
  State<CWRow> createState() => CWRowState();

  @override
  void initSlot(String path) {
    final nb = getNbChild(getDefChild());
    for (int i = 0; i < nb; i++) {
      addSlotPath('$path.Cont$i',
          SlotConfig('${ctx.xid}Cont$i', constraintEntity: 'CWRowConstraint'));
    }
  }

  @override
  int getDefChild() {
    return 2;
  }
}

class CWRowState extends StateCW<CWRow> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> listSlot = [];
    final nb = widget.getNbChild(widget.getDefChild());
    for (var i = 0; i < nb; i++) {
      listSlot.add(widget.getCell(i, true, canFill: true, canWidth: true));
    }

    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: listSlot);
  }
}

////////////////////////////////////////////////////////////////////////
mixin CWDroppable {
  Widget getDropZone(Widget child) {
    return DragTarget<DragQueryCtx>(
        builder: (context, candidateItems, rejectedItems) {
      return AnimatedScale(
          scale: candidateItems.isEmpty ? 1 : 0.95,
          duration: const Duration(milliseconds: 100),
          child: child);
    }, onWillAccept: (item) {
      return true;
    }, onAccept: (item) async {
      onDragQuery(item);
    });
  }

  void onDragQuery(DragQueryCtx query);

  static const double borderDrag = 10;

  Widget getDropQuery(double h) {
    return getDropZone(Container(
        margin: const EdgeInsets.fromLTRB(
            borderDrag, borderDrag, borderDrag, borderDrag),
        height: h,
        child: DottedBorder(
            color: Colors.grey,
            dashPattern: const <double>[6, 4],
            strokeWidth: 2,
            child: const Center(
                child: IntrinsicWidth(
                    child: Row(children: [
              Text('Drag query here'),
              Icon(Icons.filter_alt)
            ]))))));
  }
}

class SlotContainerAction extends SlotAction {
  @override
  bool canDelete() {
    return true;
  }

  @override
  bool canAddBottom() {
    return true;
  }

  @override
  bool canAddTop() {
    return true;
  }

  @override
  bool doDelete(CWWidgetCtx ctx) {
    int i = ctx.pathWidget.lastIndexOf('.Cont');
    int idxChild = int.parse(ctx.pathWidget.substring(i + 5));
    CWContainer parent = ctx.getParentCWWidget() as CWContainer;
    int nbChild = parent.getNbChild(parent.getDefChild());

    CoreDataEntity prop = PropBuilder.preparePropChange(
        ctx.loader, DesignCtx().forDesign(parent.ctx));
    prop.value['count'] = nbChild - 1;

    if (idxChild < nbChild - 1) {
      for (var i = idxChild + 1; i < nbChild; i++) {
        debugPrint('move $i');
        String path = '${parent.ctx.pathWidget}.Cont$i';
        String pathTo = '${parent.ctx.pathWidget}.Cont${i - 1}';
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

  bool _addBottomOrTop(CWWidgetCtx ctx, bool top) {
    int ic = ctx.pathWidget.lastIndexOf('.Cont');
    int idxChild = int.parse(ctx.pathWidget.substring(ic + 5));
    CWContainer parent = ctx.getParentCWWidget() as CWContainer;
    int nbChild = parent.getNbChild(parent.getDefChild());

    CoreDataEntity prop = PropBuilder.preparePropChange(
        ctx.loader, DesignCtx().forDesign(parent.ctx));
    prop.value['count'] = nbChild + 1;
    parent
      ..repaint()
      ..select();

    // delay pour avoir les nouveaux slot dans les findSlotByPath
    Future.delayed(const Duration(milliseconds: 1), () {
      if (idxChild < nbChild - 1 + (top ? 1 : 0)) {
        for (var i = nbChild - 1; i > (idxChild - (top ? 1 : 0)); i--) {
          debugPrint('move $i');
          String path = '${parent.ctx.pathWidget}.Cont$i';
          String pathTo = '${parent.ctx.pathWidget}.Cont${i + 1}';
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

  @override
  bool addBottom(CWWidgetCtx ctx) {
    return _addBottomOrTop(ctx, false);
  }

  @override
  bool addTop(CWWidgetCtx ctx) {
    return _addBottomOrTop(ctx, true);
  }

  @override
  bool canMoveBottom() {
    return true;
  }

  @override
  bool moveBottom(CWWidgetCtx ctx) {
    int ic = ctx.pathWidget.lastIndexOf('.Cont');
    int idxChild = int.parse(ctx.pathWidget.substring(ic + 5));
    CWContainer parent = ctx.getParentCWWidget() as CWContainer;
    int nbChild = parent.getNbChild(parent.getDefChild());

    if (idxChild < nbChild - 1) {
      debugPrint('move $idxChild');
      String path = '${parent.ctx.pathWidget}.Cont$idxChild';
      String pathTo = '${parent.ctx.pathWidget}.Cont${idxChild + 1}';
      var v = ctx.findWidgetByPath(path);
      var v2 = ctx.findSlotByPath(pathTo);
      if (v != null) {
        DesignActionManager().doSwap(v.ctx.getSlot()!.ctx, v2!.ctx);
      }
    }
    return true;
  }

  @override
  bool canMoveTop() {
    return true;
  }

  @override
  bool moveTop(CWWidgetCtx ctx) {
    int ic = ctx.pathWidget.lastIndexOf('.Cont');
    int idxChild = int.parse(ctx.pathWidget.substring(ic + 5));
    CWContainer parent = ctx.getParentCWWidget() as CWContainer;
    //int nbChild = parent.getNbChild(parent.getDefChild());

    if (idxChild > 0) {
      debugPrint('move $idxChild');
      String path = '${parent.ctx.pathWidget}.Cont$idxChild';
      String pathTo = '${parent.ctx.pathWidget}.Cont${idxChild - 1}';
      var v = ctx.findWidgetByPath(path);
      var v2 = ctx.findSlotByPath(pathTo);
      if (v != null) {
        DesignActionManager().doSwap(v.ctx.getSlot()!.ctx, v2!.ctx);
      }
    }
    return true;
  }
}
