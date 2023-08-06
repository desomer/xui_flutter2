import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/designer.dart';

import '../../designer/action_manager.dart';
import 'cw_core_selector.dart';
import 'cw_core_widget.dart';

class CWSlot extends CWWidget {
  const CWSlot({required super.key, this.childForced, required super.ctx});

  final Widget? childForced;

  @override
  State<CWSlot> createState() => _CWSlotState();

  @override
  initSlot(String path) {
    throw UnimplementedError();
  }
}

class _SlotDesign {
  _SlotDesign(this.contentWidget, this.constraints);
  Widget? contentWidget;
  BoxConstraints constraints;
}

class _CWSlotState extends StateCW<CWSlot> {
  @override
  Widget build(BuildContext context) {
    initSlot();

    Widget? contentWidget = widget.childForced ?? widget.ctx.getWidgetInSlot();

    return LayoutBuilder(builder: (context, constraints) {
      return widget.ctx.loader.mode == ModeRendering.design
          ? getSelector(contentWidget, _SlotDesign(contentWidget, constraints))
          : getSlotDesign(
              contentWidget, _SlotDesign(contentWidget, constraints));
    });
  }

  void initSlot() {
    widget.ctx.inSlot = widget;
    SlotConfig? slotConfig =
        widget.ctx.factory.mapSlotConstraintByPath[widget.ctx.pathWidget];

    if (slotConfig == null) {
      // init les slot lié a un ajout par les properties
      CoreDesigner.ofFactory().initSlot();
      slotConfig =
          widget.ctx.factory.mapSlotConstraintByPath[widget.ctx.pathWidget];
    }

    if (slotConfig != null) {
      slotConfig.slot = widget;
      // init le design Constraint du slot
      widget.ctx.designEntity ??=
          widget.ctx.factory.mapConstraintByXid[slotConfig.xid]?.designEntity;
    }
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

  SelectorWidget getSelector(Widget? widgetToDisplay, _SlotDesign slotDesign) {
    return SelectorWidget(
      ctx: widget.ctx,
      child: getSlotDesign(widgetToDisplay, slotDesign),
    );
  }

  Widget getSlotDesign(Widget? widgetToDisplay, _SlotDesign slotDesign) {
    if (widgetToDisplay != null) {
      return widgetToDisplay;
    } else {
      //bool hasBoundedHeight = slotDesign.constraints.hasBoundedHeight;

      var slot = Center(
          child: Text(
        'Slot ${widget.ctx.xid}', //${widget.ctx.xid}
        style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      ));

      return getDropZone(DottedBorder(
          color: Colors.grey,
          dashPattern: const <double>[6, 6],
          strokeWidth: 1,
          child: slot));
    }
  }
}
