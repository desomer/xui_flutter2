import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/designer.dart';

import '../../designer/action_manager.dart';
import 'cw_core_selector.dart';
import 'cw_core_widget.dart';

// ignore: must_be_immutable
class CWSlot extends CWWidget {
  CWSlot({required super.key, this.childForced, required super.ctx});

  Widget? childForced;

  @override
  State<CWSlot> createState() => _CWSlotState();

  @override
  initSlot(String path) {
    throw UnimplementedError();
  }
}

class _CWSlotState extends StateCW<CWSlot> {
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

    Widget? contentWidget = widget.childForced ?? widget.ctx.getWidgetInSlot();

    return widget.ctx.modeRendering == ModeRendering.design
        ? getSelector(contentWidget)
        : getSlotDesign(contentWidget);
  }

  /////////////////////////////////////////////////////////////////
  Widget getDropZone(Widget child) {
    return DragTarget<DragCtx>(
        builder: (context, candidateItems, rejectedItems) {
      return AnimatedScale(
          scale: candidateItems.isEmpty ? 1 : 0.95,
          duration: const Duration(milliseconds: 100),
          child: child);
    }, onWillAccept: (item) {
      bool isParent = item?.srcWidgetCtx != null &&
          widget.ctx.pathWidget.startsWith(item!.srcWidgetCtx!.pathWidget);
      return !isParent;
    }, onAccept: (item) {
      if (item.srcWidgetCtx == null) {
        debugPrint(
            'drop ${item.component?.impl} on ${widget.ctx.xid} ${widget.ctx.pathDataDesign ?? 'no design'}');
        DesignActionManager().doCreate(widget.ctx, item.component!);
      } else {
        debugPrint(
            'move ${item.srcWidgetCtx!.xid} on ${widget.ctx.xid} ${widget.ctx.pathDataDesign ?? 'no design'}');
        DesignActionManager().doMove(item.srcWidgetCtx!, widget.ctx);
      }

      setState(() {});
    });
  }

  Widget getSlotDesign(Widget? widgetToDisplay) {
    if (widgetToDisplay != null) {
      return widgetToDisplay;
    } else {
      return getDropZone(DottedBorder(
          color: Colors.grey,
          dashPattern: const <double>[6, 6],
          strokeWidth: 1,
          child: const Center(
              child: Text(
            'Slot',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ))));
    }
  }

  SelectorWidget getSelector(Widget? widgetToDisplay) {
    return SelectorWidget(
      ctx: widget.ctx,
      child: getSlotDesign(widgetToDisplay),
    );
  }
}
