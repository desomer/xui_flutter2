import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

import '../data/core_data.dart';
import 'cw_core_widget.dart';

mixin CWDroppableEvent {
  Widget getDropZoneEvent(CWWidgetCtx ctx, Widget child) {
    if (ctx.modeRendering == ModeRendering.view) {
      return child;
    }

    return DragTarget<DragEventCtx>(
        builder: (context, candidateItems, rejectedItems) {
      return AnimatedScale(
          scale: candidateItems.isEmpty ? 1 : 0.95,
          duration: const Duration(milliseconds: 100),
          child: child);
    }, onWillAccept: (item) {
      return true;
    }, onAccept: (item) async {
      onDragEvent(item);
    });
  }

  void onDragEvent(DragEventCtx query);
}

mixin CWDroppableQuery {
  Widget getDropZone(Widget child) {
    return DragTarget<DragQueryCtx>(
        builder: (context, candidateItems, rejectedItems) {
      return AnimatedScale(
          scale: candidateItems.isEmpty ? 1 : 0.95,
          duration: const Duration(milliseconds: 100),
          child: child);
    }, onWillAccept: (item) {
      return true;
    }, onAccept: (item) async {
      onDragQuery(item);
    });
  }

  void onDragQuery(DragQueryCtx query);

  static const double borderDrag = 10;

  Widget getDropQuery(double h) {
    return getDropZone(Container(
        margin: const EdgeInsets.fromLTRB(
            borderDrag, borderDrag, borderDrag, borderDrag),
        height: h,
        child: DottedBorder(
            color: Colors.grey,
            dashPattern: const <double>[6, 4],
            strokeWidth: 2,
            child: const Center(
                child: IntrinsicWidth(
                    child: Row(children: [
              Text('Drag query or result or param here'),
              Icon(Icons.filter_alt)
            ]))))));
  }
}

mixin DraggableWidget {
  Offset dragAnchorStrategy(
      Draggable<Object> d, BuildContext context, Offset point) {
    return Offset(d.feedbackOffset.dx + 25, d.feedbackOffset.dy - 5);
  }

  Widget getDraggable(DragCtx event, Widget child) {
    return Draggable<DragCtx>(
        dragAnchorStrategy: dragAnchorStrategy,
        onDragStarted: () {},
        data: event,
        feedback: Container(
            height: 30,
            width: 100,
            color: Colors.grey,
            child: const Center(child: Icon(Icons.abc))),
        child: child);
  }
}

/////////////////////////////////////////////////////////////////

class DragCtx {}

class DragEventCtx extends DragCtx
{}

class DragPageCtx extends DragEventCtx {
  DragPageCtx(this.page);
  CoreDataEntity page;
}

class DragRepositoryEventCtx extends DragEventCtx {
  DragRepositoryEventCtx(this.id);
  String id;
}

class DragQueryCtx extends DragCtx {
  DragQueryCtx(this.query);
  CoreDataEntity query;
}
