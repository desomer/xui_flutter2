import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';

import '../core/widget/cw_core_widget.dart';

// ignore: must_be_immutable
abstract class CWContainer extends CWWidget {
  CWContainer({Key? key, required super.ctx}) : super(key: key);

  int getNbChild() {
    return ctx.entityForFactory?.getInt("count", 3) ?? 3;
  }

  bool isFillHeight() {
    return ctx.entityForFactory?.getBool("fillHeight", true) ?? true;
  }

  Widget getCell(int i) {
    var slot = CWSlot(ctx: createChildCtx("Cont", i));
    CWWidgetCtx? constraint = ctx.factory.mapConstraintByXid[slot.ctx.xid];
    print("getCell -------- ${slot.ctx.xid} $constraint");

    int flex = constraint?.entityForFactory?.value["flex"] ?? 1;

    if (isFillHeight()) {
      return Flexible(flex: flex, fit: FlexFit.loose, child: slot);
    } else {
      return slot;
    }
  }
}

// ignore: must_be_immutable
class CWColumn extends CWContainer {
  CWColumn({Key? key, required super.ctx}) : super(key: key);

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

class CWColumnState extends State<CWColumn> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> listSlot = [];
    final nb = widget.getNbChild();
    for (var i = 0; i < nb; i++) {
      listSlot.add(widget.getCell(i));
    }

    return Column(children: listSlot);
  }
}

// ignore: must_be_immutable
class CWRow extends CWContainer {
  CWRow({Key? key, required super.ctx}) : super(key: key);

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

class CWRowState extends State<CWRow> {
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
