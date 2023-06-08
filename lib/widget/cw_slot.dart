import 'package:flutter/material.dart';

import 'cw_builder.dart';
import 'cw_selector.dart';

// ignore: must_be_immutable
class CWSlot extends CWWidget {
  CWSlot({super.key, this.child, required super.ctx});

  Widget? child;

  @override
  State<CWSlot> createState() => _CWSlotState();
}

class _CWSlotState extends State<CWSlot> {
  @override
  Widget build(BuildContext context) {
    final String childXid = widget.ctx.factory.mapChild[widget.ctx.xid] ?? '';
    Widget? w = widget.child ?? widget.ctx.factory.mapWidget[childXid];
    if (widget.child is CWWidget) {
      w = widget.child;
    }
    if (w is CWWidget) {
      w.ctx.path = widget.ctx.path;
      debugPrint(
          'path <${widget.ctx.path}> id=${widget.ctx.xid} design=${w.entity?.type ?? 'no'}');
    }

    return SelectorWidget(
      ctx: widget.ctx,
      child: w ?? Center(child: Text('<${widget.ctx.xid}>')),
    );
  }
}
