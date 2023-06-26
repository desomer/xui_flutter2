import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';

import '../core/widget/cw_core_widget.dart';

// ignore: must_be_immutable
class CWColumn extends CWWidget {
  int getNbChild() {
    return ctx.entityForFactory?.getInt("count", 3) ?? 3;
  }

  bool isFillHeight() {
    return ctx.entityForFactory?.getBool("fillHeight", true) ?? true;
  }

  CWColumn({Key? key, required super.ctx}) : super(key: key);

  @override
  State<CWColumn> createState() => CWColumnState();

  @override
  initSlot(String path) {
    final nb = getNbChild();
    for (int i = 0; i < nb; i++) {
      addSlotPath('$path.Cont$i', SlotConfig('${ctx.xid}Cont$i'));
    }
  }
}

class CWColumnState extends State<CWColumn> {
  Widget getCell(int i) {
    var slot = CWSlot(ctx: widget.createChildCtx("Cont", i));
    if (widget.isFillHeight()) {
      return Expanded(child: slot);
    } else {
      return slot;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> listSlot = [];
    final nb = widget.getNbChild();
    for (var i = 0; i < nb; i++) {
      listSlot.add(getCell(i));
    }

    return Column(children: listSlot);
  }
}

// ignore: must_be_immutable
class CWRow extends CWWidget {
  int getNbChild() {
    return ctx.entityForFactory?.getInt("count", 3) ?? 3;
  }

  CWRow({Key? key, required super.ctx}) : super(key: key);

  @override
  State<CWRow> createState() => CWRowState();

  @override
  initSlot(String path) {
    final nb = getNbChild();
    for (int i = 0; i < nb; i++) {
      addSlotPath('$path.Cont$i', SlotConfig('${ctx.xid}Cont$i'));
    }
  }
}

class CWRowState extends State<CWRow> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> listSlot = [];
    final nb = widget.getNbChild();
    for (var i = 0; i < nb; i++) {
      listSlot
          .add(Expanded(child: CWSlot(ctx: widget.createChildCtx("Cont", i))));
    }

    return Row(children: listSlot);
  }
}
