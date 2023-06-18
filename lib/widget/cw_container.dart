import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';

import '../core/widget/cw_core_widget.dart';

// ignore: must_be_immutable
class CWContainer extends CWWidget {
  int getNbChild() {
    return ctx.entity?.getInt("count", 1) ?? 1;
  }

  CWContainer({Key? key, required super.ctx}) : super(key: key);

  @override
  State<CWContainer> createState() => CWContainerState();

  @override
  initSlot(String path) {
    final nb = getNbChild();
    for (int i = 0; i < nb; i++) {
      addSlotPath('$path.Cont$i', '${ctx.xid}Cont$i');
    }
  }
}

class CWContainerState extends State<CWContainer> {
  @override
  Widget build(BuildContext context) {
    final List<CWSlot> listSlot = [];
    final nb = widget.getNbChild();
    for (var i = 0; i < nb; i++) {
      listSlot.add(CWSlot(ctx: widget.createChildCtx("Cont", i)));
    }

    return Column(children: listSlot);
  }
}
