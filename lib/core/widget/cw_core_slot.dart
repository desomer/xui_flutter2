import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/designer.dart';

import '../../designer/widget_component.dart';
import 'cw_core_selector.dart';
import 'cw_core_widget.dart';

// ignore: must_be_immutable
class CWSlot extends CWWidget {
  CWSlot({required super.key, this.child, required super.ctx});

  Widget? child;

  @override
  State<CWSlot> createState() => _CWSlotState();

  @override
  initSlot(String path) {
    throw UnimplementedError();
  }
}

class _CWSlotState extends StateCW<CWSlot> {
  Widget getDrop(Widget child) {
    return DragTarget<ComponentDesc>(
        builder: (context, candidateItems, rejectedItems) {
          return child;
        },
        onWillAccept: (value) => true,
        onAccept: (item) {
          debugPrint(
              '${item.impl}=>${widget.ctx.xid} ${widget.ctx.pathDataDesign ?? 'no design'}');

          item.addNewWidgetOn(widget);

          setState(() {});
        });
  }

  Widget getSlotDesign() {
    return getDrop(DottedBorder(
        color: Colors.grey,
        dashPattern: const <double>[6, 6],
        strokeWidth: 1,
        child: const Center(
            child: Text(
          'Slot',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ))));
  }

  @override
  Widget build(BuildContext context) {
    widget.ctx.slot = widget;
    SlotConfig? slotConfig =
        widget.ctx.factory.mapSlotConstraintByPath[widget.ctx.pathWidget];

    if (slotConfig == null) {
      // init les slot lié a un ajout par les properties
      CoreDesigner.of().factory.initSlot();
      slotConfig =
          widget.ctx.factory.mapSlotConstraintByPath[widget.ctx.pathWidget];
    }

    slotConfig!.slot = widget;

    final String childXid =
        widget.ctx.factory.mapChildXidByXid[widget.ctx.xid] ?? '';

    Widget? widgetToDisplay =
        widget.child ?? widget.ctx.factory.mapWidgetByXid[childXid];

    return widget.ctx.modeRendering == ModeRendering.design
        ? getSelector(widgetToDisplay)
        : widgetToDisplay ?? getSlotDesign();
  }

  SelectorWidget getSelector(Widget? widgetToDisplay) {
    return SelectorWidget(
      ctx: widget.ctx,
      child: widgetToDisplay ?? getSlotDesign(),
    );
  }
}
