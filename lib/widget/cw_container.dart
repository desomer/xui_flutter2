import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';
import 'package:xui_flutter/designer/cw_factory.dart';
import 'package:xui_flutter/designer/designer.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_widget.dart';

abstract class CWContainer extends CWWidget {
  const CWContainer({Key? key, required super.ctx}) : super(key: key);

  int getNbChild() {
    return ctx.designEntity?.getInt("count", 3) ?? 3;
  }

  bool isFill(bool def) {
    return ctx.designEntity?.getBool("fill", def) ?? def;
  }

  Widget getCell(int i, bool defFill, {required bool canFill}) {
    var slot = CWSlot(
        key: GlobalKey(debugLabel: 'slot ${ctx.xid}$i'),
        ctx: createChildCtx("Cont", i));
    CWWidgetCtx? constraint = ctx.factory.mapConstraintByXid[slot.ctx.xid];
    //print("getCell -------- ${slot.ctx.xid} $constraint");

    int flex = constraint?.designEntity?.value["flex"] ?? 1;
    bool loose = constraint?.designEntity?.value["tight/loose"] ?? false;
    int? height = constraint?.designEntity?.value["height"];

    // var slot2 = IntrinsicHeight(child: slot);

    if (height != null && height > 5) {
      return SizedBox(height: height.toDouble(), child: slot);
    } else if (isFill(defFill) && canFill) {
      return Flexible(
          flex: flex, fit: loose ? FlexFit.loose : FlexFit.tight, child: slot);
    } else {
      return slot;
    }
  }
}

class CWColumn extends CWContainer {
  const CWColumn({Key? key, required super.ctx}) : super(key: key);

  @override
  State<CWColumn> createState() => CWColumnState();

  @override
  initSlot(String path) {
    final nb = getNbChild();
    for (int i = 0; i < nb; i++) {
      addSlotPath('$path.Cont$i',
          SlotConfig('${ctx.xid}Cont$i', constraintEntity: "CWColConstraint"));
    }
  }

  static initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget("CWColumn",
            (CWWidgetCtx ctx) => CWColumn(key: ctx.getKey(), ctx: ctx))
        .addAttr('count', CDAttributType.CDint)
        .withAction(AttrActionDefault(3))
        .addAttr('fill', CDAttributType.CDbool)
        .withAction(AttrActionDefault(true));

    c.collection
        .addObject('CWColConstraint')
        .addAttr('flex', CDAttributType.CDint)
        .addAttr('tight/loose', CDAttributType.CDbool)
        .addAttr('height', CDAttributType.CDint);
    // .addAttr('min (ConstrainedBox)', CDAttributType.CDint)
    // .addAttr('max (ConstrainedBox)', CDAttributType.CDint);
    //    .addAttr('% ()', CDAttributType.CDint);
    //.addAttr('Fitted child (FittedBox)', CDAttributType.CDbool);
  }
}

class CWColumnState extends StateCW<CWColumn> {
  @override
  Widget build(BuildContext context) {
    if (widget.ctx.loader.mode == ModeRendering.design) {
      double lasth = h;

      // gestion de la zone de drop Filler
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (context.mounted && context.size is Size) {
          hm = context.size!.height;
          wm = context.size!.width;
          final nb = widget.getNbChild();
          h = 0;
          for (int i = 0; i < nb; i++) {
            String slotName = "${widget.ctx.pathWidget}.Cont$i";
            SlotConfig? sc =
                CoreDesigner.ofFactory().mapSlotConstraintByPath[slotName];
            if (sc != null) {
              GlobalKey ks = sc.slot!.key! as GlobalKey;
              h = h + ks.currentContext!.size!.height;
            }
          }
          h = hm - h;
          if (h != lasth) {
            setState(() {});
          }
        }
      });
    }

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
      debugPrint("viewportConstraints ${viewportConstraints.hasBoundedHeight}");

      final List<Widget> listStack = [];

      final List<Widget> listSlot = [];
      final nb = widget.getNbChild();
      for (var i = 0; i < nb; i++) {
        listSlot.add(widget.getCell(i, true,
            canFill: viewportConstraints.hasBoundedHeight));
      }
      listStack.add(Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: listSlot));
      // if (widget.ctx.modeRendering == ModeRendering.design) {
      //   Widget? filler = getFiller();
      //   if (filler != null) {
      //     listStack.add(filler);
      //   }
      // }

      return Stack(
          key: GlobalKey(debugLabel: "CWColumnState"), children: listStack);
    });
  }

  double h = 0;
  double hm = 0;
  double wm = 0;

  Widget? getFiller() {
    return Positioned(
        bottom: 0,
        left: 0,
        child: Container(
            height: h, width: wm, color: Colors.red.withOpacity(0.3)));
  }
}

////////////////////////////////////////////////////////////////////////
class CWRow extends CWContainer {
  const CWRow({Key? key, required super.ctx}) : super(key: key);

  static initFactory(CWWidgetCollectionBuilder c) {
    c.collection
            .addObject('CWRowConstraint')
            .addAttr('flex', CDAttributType.CDint)
            .addAttr('tight/loose', CDAttributType.CDbool)
            .addAttr('width (sizedBox)', CDAttributType.CDint)
        // .addAttr('min (ConstrainedBox)', CDAttributType.CDint)
        // .addAttr('max (ConstrainedBox)', CDAttributType.CDint)
        // .addAttr('% (FractionallySizedBox)', CDAttributType.CDint)
        // .addAttr('Fitted child (FittedBox)', CDAttributType.CDbool)
        ;

    c
        .addWidget(
            "CWRow", (CWWidgetCtx ctx) => CWRow(key: ctx.getKey(), ctx: ctx))
        .addAttr('count', CDAttributType.CDint)
        .withAction(AttrActionDefault(3))
        .addAttr('fill', CDAttributType.CDbool)
        .withAction(AttrActionDefault(true));
  }

  @override
  State<CWRow> createState() => CWRowState();

  @override
  initSlot(String path) {
    final nb = getNbChild();
    for (int i = 0; i < nb; i++) {
      addSlotPath('$path.Cont$i',
          SlotConfig('${ctx.xid}Cont$i', constraintEntity: "CWRowConstraint"));
    }
  }
}

class CWRowState extends StateCW<CWRow> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> listSlot = [];
    final nb = widget.getNbChild();
    for (var i = 0; i < nb; i++) {
      listSlot.add(widget.getCell(i, true, canFill: true));
    }

    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: listSlot);
  }
}
