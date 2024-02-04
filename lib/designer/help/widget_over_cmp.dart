import 'package:flutter/material.dart';
import '../../core/widget/cw_core_widget.dart';
import '../designer.dart';
import '../designer_breadcrumb.dart';

class WidgetOverCmp extends StatefulWidget {
  const WidgetOverCmp(
      {required this.child, required this.path, super.key, this.mode});

  @override
  State<WidgetOverCmp> createState() => _WidgetOverCmpState();
  final Widget child;
  final String path;
  final String? mode;
}

class _WidgetOverCmpState extends State<WidgetOverCmp> {
  HoverCmpManager overMgr = HoverCmpManager();

  @override
  void initState() {
    super.initState();
    overMgr.isOver = false;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onHover: (event) {
          setState(() {
            overMgr.onHover(widget.path);
          });
        },
        onExit: (event) {
          setState(() {
            overMgr.onExit();
          });
        },
        child: getClip(getHoverBox(context)));
  }

  Widget getClip(Widget child) {
    if (widget.mode == 'clip') {
      return ClipPath(clipper: TriangleClipper(true), child: child);
    }
    if (widget.mode == '1clip') {
      return ClipPath(clipper: TriangleClipper(false), child: child);
    } else {
      return child;
    }
  }

  Container getHoverBox(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            boxShadow: overMgr.isOver
                ? [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 20,
                      // offset: const Offset(-20, -20), // changes position of shadow
                    ),
                  ]
                : null,
            border: Border.all(
                color:
                    overMgr.isOver ? Colors.deepOrange : Colors.transparent)),
        child: widget.child);
  }
}

class HoverCmpManager {
  bool isOver = false;
  String? path;

  void onHover(String onPath) {
    isOver = true;
    if (CoreDesigner.ofFactory().loader.mode == ModeRendering.design &&
        path != onPath) {
      path = onPath;
      SlotConfig? config =
          CoreDesigner.ofFactory().mapSlotConstraintByPath[onPath];
      var ctx = config?.slot?.ctx;
      CoreDesigner.emit(CDDesignEvent.over, ctx);
    }
  }

  void onExit() {
    path = null;
    isOver = false;
    if (CoreDesigner.ofFactory().loader.mode == ModeRendering.design) {
      CoreDesigner.emit(CDDesignEvent.reselect, null);
    }
  }
}
