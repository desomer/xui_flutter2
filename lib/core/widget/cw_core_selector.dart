import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xui_flutter/core/data/core_data_selector.dart';

import '../../widget/cw_image.dart';
import '../../widget/cw_toolkit.dart';
import 'cw_core_widget.dart';

class SelectorActionWidget extends StatefulWidget {
  const SelectorActionWidget({super.key});

  static final GlobalKey actionPanKey = GlobalKey();
  static final GlobalKey designerKey = GlobalKey();
  static final GlobalKey rootKey = GlobalKey();
  @override
  State<SelectorActionWidget> createState() => SelectorActionWidgetState();
}

class SelectorActionWidgetState extends State<SelectorActionWidget> {
  double top = 10;
  double left = 10;
  bool _visible = false;

  @override
  Widget build(Object context) {
    return Visibility(
        visible: _visible,
        child: Positioned(
            top: top,
            left: left,
            child: SizedBox(
                height: 20,
                width: 20,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0)),
                  child: const Icon(Icons.delete, size: 15),
                  onPressed: () {},
                ))));
  }
}

// ignore: must_be_immutable
class SelectorWidget extends StatefulWidget {
  SelectorWidget({super.key, required this.child, required this.ctx});

  final GlobalKey widgetKey = GlobalKey();
  final Widget child;
  CWWidgetCtx ctx;

  static String hoverPath = '';
  // ignore: library_private_types_in_public_api
  static SelectorWidgetState? lastStateOver;

  static String lastClickPath = '';
  static SelectorWidgetState? lastStateClick;

  @override
  State<SelectorWidget> createState() => SelectorWidgetState();
}

class SelectorWidgetState extends State<SelectorWidget> {
  bool isHover = false;

  Offset dragAnchorStrategy(
      Draggable<Object> d, BuildContext context, Offset point) {
    return Offset(d.feedbackOffset.dx + 25, d.feedbackOffset.dy + 30);
  }

  final GlobalKey paintKey = GlobalKey();
  bool menuIsOpen = false;

  Widget getChild() {
    /*if (isHover) {
      return DottedBorder(
          color: Colors.blue,
          dashPattern: const <double>[8, 8],
          strokeWidth: 4,
          child: widget.child);
    } else*/
    if (isHover && SelectorWidget.lastClickPath == widget.ctx.pathWidget) {
      return DottedBorder(
          color: Colors.blue,
          dashPattern: const <double>[2, 2],
          strokeWidth: 4,
          child: widget.child);
    } else if (SelectorWidget.lastClickPath == widget.ctx.pathWidget) {
      return DottedBorder(
          color: Colors.blue,
          dashPattern: const <double>[4, 4],
          strokeWidth: 4,
          child: widget.child);
    } else {
      return widget.child;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        // margin: EdgeInsets.only(
        //     right: isHover ? 2 : 0.0,
        //     left: isHover ? 2 : 0,
        //     top: isHover ? 2 : 0.0,
        //     bottom: isHover ? 2 : 0),
        duration: const Duration(milliseconds: 200),
        child: Draggable<String>(
          dragAnchorStrategy: dragAnchorStrategy,
          data: 'ok',
          feedback: const SizedBox(
            height: 50.0,
            width: 50.0,
            child: Icon(Icons.circle),
          ),
          child: MouseRegion(
              onHover: onHover,
              onExit: onExit,
              child: Listener(
                key: widget.widgetKey,
                behavior: HitTestBehavior.opaque,
                onPointerDown: onPointerDown,
                child: RepaintBoundary(key: paintKey, child: getChild()),
              )),
        ));
  }

  void onPointerDown(PointerDownEvent d) {
    if (menuIsOpen) return;

    if (isHover) {
      showActionWidget();
    }

    if (isHover) {
      CoreDataSelector().doSelectWidget(widget, d.buttons);

      _capturePng();
      doSelection();

      if (d.buttons == 2) {
        doRightSelection(d);
      }
    }
  }

  void doRightSelection(PointerDownEvent d) {
    final Offset position =
        CwToolkit.getPosition(widget.widgetKey, SelectorActionWidget.rootKey);

    menuIsOpen = true;
    Future.delayed(const Duration(milliseconds: 200), () {
      menuIsOpen = false;
    });

    _showPopupMenu(Offset(position.dx + d.localPosition.dx + 10,
        position.dy + d.localPosition.dy + 10));
  }

  void doSelection() {
    if (SelectorWidget.lastClickPath != widget.ctx.pathWidget) {
      SelectorWidget.lastClickPath = widget.ctx.pathWidget;

      if (SelectorWidget.lastStateClick != null &&
          SelectorWidget.lastStateClick!.mounted) {
        SelectorWidget.lastStateClick?.setState(() {});
        debugPrint(
            "deselection ${SelectorWidget.lastStateClick!.widget.ctx.pathWidget}");
      }

      setState(() {
        debugPrint("selection ${widget.ctx.pathWidget}");
        SelectorWidget.lastStateClick = this;
      });
    }
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
      // debugPrint(
      //     'onHover ${widget.ctx.pathWidget} ${SelectorWidget.hoverPath}');

      removeLastOver();

      setState(() {
        isHover = true;
        SelectorWidget.lastStateOver = this;
        SelectorWidget.hoverPath = widget.ctx.pathWidget;
      });
    }
  }

  // void removeLastClick() {
  //   final SelectorWidgetState? current = SelectorWidget.lastStateClick;

  //   final bool remove = SelectorWidget.lastStateClick != null &&
  //       SelectorWidget.lastClickPath != widget.ctx.pathWidget &&
  //       SelectorWidget.lastStateClick!.mounted;

  //   if (remove) {
  //     current?.setState(() {});
  //   }
  // }

  void removeLastOver() {
    final SelectorWidgetState? current = SelectorWidget.lastStateOver;

    final bool remove = SelectorWidget.lastStateOver != null &&
        SelectorWidget.hoverPath != widget.ctx.pathWidget &&
        SelectorWidget.lastStateOver!.mounted;

    if (remove) {
      current?.setState(() {
        current.isHover = false;
      });
    }
  }

  void showActionWidget() {
    // ignore: cast_nullable_to_non_nullable
    final SelectorActionWidgetState st = SelectorActionWidget
        .actionPanKey.currentState as SelectorActionWidgetState;
    st.setState(() {
      final Offset position = CwToolkit.getPosition(
          widget.widgetKey, SelectorActionWidget.designerKey);

      // ignore: cast_nullable_to_non_nullable
      final RenderBox box =
          widget.widgetKey.currentContext!.findRenderObject() as RenderBox;

      st.left = position.dx;
      st.top = position.dy + box.size.height;
      st._visible = true;
    });
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
    RenderRepaintBoundary? boundary =
        paintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

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
