import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xui_flutter/designer/designer.dart';

import '../../designer/action_manager.dart';
import '../../widget/cw_image.dart';
import '../../widget/cw_toolkit.dart';
import 'cw_core_selector_action.dart';
import 'cw_core_widget.dart';


class SelectorWidget extends StatefulWidget {
  const SelectorWidget({super.key, required this.child, required this.ctx});

  final Widget child;
  final CWWidgetCtx ctx;

  static String hoverPath = '';
  static SelectorWidgetState? lastStateOver;

  @override
  State<SelectorWidget> createState() => SelectorWidgetState();
}

class SelectorWidgetState extends State<SelectorWidget> {
  Offset dragAnchorStrategy(
      Draggable<Object> d, BuildContext context, Offset point) {
    return Offset(d.feedbackOffset.dx + 25, d.feedbackOffset.dy + 30);
  }

  bool isHover = false;
  bool menuIsOpen = false;
  double hm = 0;
  double wm = 0;

  Widget _getBorderOver(Widget child, Color color, double stroke) {
    var borderOver = MouseRegion(
      opaque: false,
      child: DottedBorder(
        color: color,
        dashPattern: const <double>[4, 4],
        strokeWidth: stroke,
        child: SizedBox(width: wm, height: hm),
      ),
    );

    return Stack(
      //  key: GlobalKey(debugLabel: "_getBorderOver ${widget.ctx.xid}"),
      children: [child, borderOver],
    );
  }

  Widget getSelectorWithChild(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (context.mounted && context.size is Size) {
        var hm2 = context.size!.height - 4;
        var wm2 = context.size!.width - 4;

        if (hm2 != hm || wm2 != wm) {
          setState(() {
            hm = hm2;
            wm = wm2;
          });
        }
      }
    });

    if (isHover) {
      return _getBorderOver(widget.child, Colors.grey, 2);
    } else if (widget.ctx.isSelected()) {
      return _getBorderOver(widget.child, Colors.deepOrange, 4);
    } else {
      return widget.child;
    }
  }

  GlobalKey? captureKey;

  @override
  Widget build(BuildContext context) {
    // ne creer pas de key sinon perte de focus
    captureKey ??= GlobalKey(debugLabel: "captureKey ${widget.ctx.xid}");

    return Draggable<DragCtx>(
      dragAnchorStrategy: dragAnchorStrategy,
      data: DragCtx(null, widget.ctx),
      feedback: const SizedBox(
        height: 50.0,
        width: 50.0,
        child: Icon(Icons.circle),
      ),
      child: MouseRegion(
          onHover: onHover,
          onExit: onExit,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: onPointerDown,
            child: RepaintBoundary(
                key: captureKey, child: getSelectorWithChild(context)),
          )),
    );
  }

  void onPointerDown(PointerDownEvent d) {
    if (menuIsOpen) return;

    widget.ctx.lastEvent = d;

    if (isHover) {
      bool isSelectionChange = !widget.ctx.isSelected();

      if (isSelectionChange) {
        CoreDesigner.emit(CDDesignEvent.select, widget.ctx);

        setState(() {
          debugPrint("selection ${widget.ctx.pathWidget}");
        });
      }

      _capturePng();

      if (d.buttons == 2) {
        doRightSelection(d);
      }
    }
  }

  void doRightSelection(PointerDownEvent d) {
    final Offset position =
        CwToolkit.getPosition(captureKey!, SelectorActionWidget.rootKey);

    menuIsOpen = true;
    Future.delayed(const Duration(milliseconds: 200), () {
      menuIsOpen = false;
    });

    _showPopupMenu(Offset(position.dx + d.localPosition.dx + 10,
        position.dy + d.localPosition.dy + 10));
  }

  void onExit(PointerExitEvent e) {
    if (menuIsOpen) return; // ouverture du menu ne ferme pas le hover

    if (isHover) {
      setState(() {
        if (SelectorWidget.hoverPath == widget.ctx.pathWidget) {
          //debugPrint('onExit hover ${widget.ctx.pathWidget} =>$e');
          SelectorWidget.hoverPath = '';
          SelectorWidget.lastStateOver = null;
        }
        isHover = false;
      });
    }
  }

  void onHover(PointerHoverEvent e) {
    final bool isParent = SelectorWidget.hoverPath != widget.ctx.pathWidget &&
        SelectorWidget.hoverPath.startsWith(widget.ctx.pathWidget);

    if (!isParent && !isHover) {
      removeLastOver();

      setState(() {
        isHover = true;
        SelectorWidget.lastStateOver = this;
        SelectorWidget.hoverPath = widget.ctx.pathWidget;
      });
    }
  }

  void removeLastOver() {
    final SelectorWidgetState? current = SelectorWidget.lastStateOver;

    final bool remove =
        current != null && SelectorWidget.hoverPath != widget.ctx.pathWidget;

    if (remove && current.mounted) {
      current.setState(() {
        current.isHover = false;
      });
    }
  }

  void _showPopupMenu(Offset offset) async {
    final double left = offset.dx;
    final double top = offset.dy;

    // showDialog(
    //     context: ctx,
    //     builder: (BuildContext c1) => PopupMenuButton(
    //           child: Center(child: Text('click here')),
    //           itemBuilder: (c2) {
    //             return List.generate(5, (index) {
    //               return PopupMenuItem(
    //                 child: Text('button no $index'),
    //               );
    //             });
    //           },
    //         ));

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, left, 100),
      items: [
        const PopupMenuItem(
          value: 1,
          child: Text('capture Image'),
        ),
        const PopupMenuItem(
          value: 2,
          child: Text('Edit'),
        ),
        const PopupMenuItem(
          value: 3,
          child: Text('Delete'),
        ),
      ],
      elevation: 8.0,
    ).then((int? value) {
      // NOTE: even you didnt select item this method will be called with null of value so you should call your call back with checking if value is not null , value is the value given in PopupMenuItem
      if (value != null) {
        debugPrint('popup click $value');
      }
    });
  }

  _capturePng() async {
    RenderRepaintBoundary? boundary = captureKey?.currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;

    /// convert boundary to image
    final image = await boundary!.toImage(pixelRatio: 0.5);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final imageBytes = byteData?.buffer.asUint8List();

    Widget wi = Image.memory(imageBytes!);

    CwImageState.wi = wi;

    debugPrint(
        'Capture PNG ===========> ${image.toString()} ${imageBytes.length}');
  }
}
