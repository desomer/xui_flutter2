import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';
import 'package:xui_flutter/designer/designer.dart';

import '../core/widget/cw_core_widget.dart';

abstract class CWContainer extends CWWidget {
  const CWContainer({Key? key, required super.ctx}) : super(key: key);

  int getNbChild() {
    return ctx.entityForFactory?.getInt("count", 3) ?? 3;
  }

  bool isFill() {
    return ctx.entityForFactory?.getBool("fill", true) ?? true;
  }

  Widget getCell(int i) {
    var slot = CWSlot(
        key: GlobalKey(debugLabel: 'slot ${ctx.xid}'),
        ctx: createChildCtx("Cont", i));
    CWWidgetCtx? constraint = ctx.factory.mapConstraintByXid[slot.ctx.xid];
    //print("getCell -------- ${slot.ctx.xid} $constraint");

    int flex = constraint?.entityForFactory?.value["flex"] ?? 1;

    if (isFill()) {
      return Flexible(flex: flex, fit: FlexFit.loose, child: slot);
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
}

class CWColumnState extends StateCW<CWColumn> {
  @override
  Widget build(BuildContext context) {
    if (widget.ctx.modeRendering == ModeRendering.design) {
      double lasth = h;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (context.mounted && context.size is Size) {
          hm = context.size!.height;
          wm = context.size!.width;
          final nb = widget.getNbChild();
          h = 0;
          for (int i = 0; i < nb; i++) {
            String slotName = "${widget.ctx.pathWidget}.Cont$i";
            SlotConfig? sc =
                CoreDesigner.of().factory.mapSlotConstraintByPath[slotName];
            if (sc != null) {
              GlobalKey ks = sc.slot!.key! as GlobalKey;
              h = h + ks.currentContext!.size!.height;
            }
          }
          h = hm - h;
          print("h=$h");
          if (h != lasth) {
            setState(() {});
          }
        }
      });
    }

    final List<Widget> listStack = [];

    final List<Widget> listSlot = [];
    final nb = widget.getNbChild();
    for (var i = 0; i < nb; i++) {
      listSlot.add(widget.getCell(i));
    }
    listStack.add(Column(children: listSlot));
    if (widget.ctx.modeRendering == ModeRendering.design) {
      Widget? filler = getFiller();
      if (filler != null) {
        listStack.add(filler);
      }
    }

    return Stack(children: listStack);
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

class CWRow extends CWContainer {
  const CWRow({Key? key, required super.ctx}) : super(key: key);

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
      listSlot.add(widget.getCell(i));
    }

    return Row(children: listSlot);
  }
}
