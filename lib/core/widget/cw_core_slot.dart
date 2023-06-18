import 'package:flutter/material.dart';

import 'cw_core_selector.dart';
import 'cw_core_widget.dart';

// ignore: must_be_immutable
class CWSlot extends CWWidget {
  CWSlot({super.key, this.child, required super.ctx});

  Widget? child;

  @override
  State<CWSlot> createState() => _CWSlotState();

  @override
  initSlot(String path) {
    throw UnimplementedError();
  }
}

class _CWSlotState extends State<CWSlot> {
  @override
  Widget build(BuildContext context) {
    Key inkWellKey = ValueKey(widget.ctx.xid);

    final String childXid =
        widget.ctx.factory.mapChildXidByXid[widget.ctx.xid] ?? '';
    Widget? w = widget.child ?? widget.ctx.factory.mapWidgetByXid[childXid];
    // if (widget.child is CWWidget) {
    //   w = widget.child;
    // }
    // if (w is CWWidget) {
    //   w.ctx.pathWidget = widget.ctx.pathWidget;  // path passer par le parent
    //   // change le path
    //   //print(">> child >> ${w.ctx.pathWidget}");
    // }

    return widget.ctx.modeRendering == ModeRendering.design
        ? SelectorWidget(
            key: inkWellKey,
            ctx: widget.ctx,
            child: w ?? Center(child: Text('<${widget.ctx.xid}>')),
          )
        : w ?? Center(child: Text('<${widget.ctx.xid}>'));
  }
}
