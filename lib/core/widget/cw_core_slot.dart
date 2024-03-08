import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/designer.dart';

import '../../designer/action_manager.dart';
import '../../designer/designer_selector_component.dart';
import 'cw_core_drag.dart';
import 'cw_core_selector.dart';
import 'cw_core_widget.dart';
import 'cw_factory.dart';

class CWSlot extends CWWidget {
  const CWSlot(
      {required super.key,
      this.childForced,
      required super.ctx,
      required this.type,
      this.slotAction});

  final Widget? childForced;
  final String type;
  final SlotAction? slotAction;

  @override
  State<CWSlot> createState() => _CWSlotState();

  @override
  void initSlot(String path, ModeParseSlot mode) {
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
    initSlot(ModeParseSlot.build);

    Widget? contentWidget = widget.childForced ?? widget.ctx.getWidgetInSlot();

    return LayoutBuilder(builder: (context, constraints) {
      return widget.ctx.modeRendering == ModeRendering.design
          ? getSelector(contentWidget, _SlotDesign(contentWidget, constraints))
          : contentWidget ?? Container();
      // : getSlotDesign(
      //     contentWidget, _SlotDesign(contentWidget, constraints));
    });
  }

  void initSlot(ModeParseSlot mode) {
    widget.ctx.inSlot = widget;
    SlotConfig? slotConfig =
        widget.ctx.factory.mapSlotConstraintByPath[widget.ctx.pathWidget];

    if (slotConfig == null) {
      // init tout les slot lié si ajout par drag
      CoreDesigner.ofFactory().initSlot(mode);
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
    }, onWillAcceptWithDetails: (details) {
      if (details.data is DragComponentCtx) {
        DragComponentCtx item = details.data as DragComponentCtx;
        bool isParent = item.srcWidgetCtx != null &&
            widget.ctx.pathWidget.startsWith(item.srcWidgetCtx!.pathWidget);
        return !isParent;
      }
      if (details.data is DragPageCtx) {
        return true;
      }
      if (details.data is DragRepositoryEventCtx) {
        return true;
      }
      return false;
    }, onAcceptWithDetails: (details) {
      if (details.data is DragComponentCtx) {
        DragComponentCtx item = details.data as DragComponentCtx;
        if (item.srcWidgetCtx == null) {
          debugPrint(
              'drop ${item.component?.impl} on ${widget.ctx.xid} ${widget.ctx.pathDataDesign ?? 'no design'}');
          DesignActionManager().doCreate(widget.ctx, item.component!);
        } else {
          if (CoreDesigner.of().isCtrlPress()) {
            debugPrint(
                'clone ${item.srcWidgetCtx!.xid} on ${widget.ctx.xid} ${widget.ctx.pathDataDesign ?? 'no design'}');
            DesignActionManager().doCloneInSlot(item.srcWidgetCtx!.getWidgetInSlot()!.ctx, widget.ctx);
          } else {
            debugPrint(
                'move ${item.srcWidgetCtx!.xid} on ${widget.ctx.xid} ${widget.ctx.pathDataDesign ?? 'no design'}');
            DesignActionManager().doMoveInSlot(item.srcWidgetCtx!, widget.ctx);
          }
        }
      } else if (details.data is DragPageCtx) {
        CWWidget w = DesignActionManager().doCreate(
          widget.ctx,
          ComponentDesc('Button', Icons.smart_button_sharp, 'CWActionLink'),
        );
        DesignActionManager().doPageAction(w.ctx, details.data as DragPageCtx);
      } else if (details.data is DragRepositoryEventCtx) {
        CWWidget w = DesignActionManager().doCreate(
          widget.ctx,
          ComponentDesc('Button', Icons.smart_button_sharp, 'CWActionLink'),
        );
        DesignActionManager()
            .doReposAction(w.ctx, details.data as DragRepositoryEventCtx);
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

      var slotEmpty = const Center(
          child: Text(
        'Drag here', //${widget.ctx.xid}
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      ));

      return getDropZone(DottedBorder(
          color: Colors.grey,
          dashPattern: const <double>[6, 6],
          strokeWidth: 1,
          child: slotEmpty));
    }
  }
}

abstract class SlotAction {
  bool canDelete();
  bool doDelete(CWWidgetCtx ctx);
  bool canAddBottom();
  bool addBottom(CWWidgetCtx ctx);
  bool canAddTop();
  bool addTop(CWWidgetCtx ctx);
  bool canMoveBottom();
  bool moveBottom(CWWidgetCtx ctx);
  bool canMoveTop();
  bool moveTop(CWWidgetCtx ctx);

  bool canAddRight();
  bool addRight(CWWidgetCtx ctx);
  bool canAddLeft();
  bool addLeft(CWWidgetCtx ctx);
  bool canMoveRight();
  bool moveRight(CWWidgetCtx ctx);
  bool canMoveLeft();
  bool moveLeft(CWWidgetCtx ctx);
}
