import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xui_flutter/designer/selector_manager.dart';

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

class ZoneDesc {
  bool visibility = false;
  double? bottom;
  double? left;
  double? top;
  double? right;
  double? width;
  double? height;
  Function? initPos;
  List<Widget> actions = [];
}

class SelectorActionWidgetState extends State<SelectorActionWidget> {
  double bottom = 10;
  double left = 10;
  double top = 10;
  double right = 10;

  bool _visible = false;

  ZoneDesc bottomZone = ZoneDesc();
  ZoneDesc topZone = ZoneDesc();
  ZoneDesc rightZone = ZoneDesc();
  ZoneDesc leftZone = ZoneDesc();

  @override
  void initState() {
    super.initState();

    bottomZone.initPos = () {
      bottomZone.top = bottom - 10;
      bottomZone.left = left;
      bottomZone.width = right - left;
      bottomZone.height = 40;

      double topBtn = 10;
      double leftBtn = (right - left) / 2;

      bottomZone.actions = [
        getAddAction(topBtn, leftBtn - 25, Icons.expand_more),
        getAddAction(topBtn, leftBtn + 5, Icons.add),
      ];
    };

    topZone.initPos = () {
      topZone.top = top - 30;
      topZone.left = left;
      topZone.width = right - left;
      topZone.height = 40;
      double topBtn = 10;
      double leftBtn = (right - left) / 2;
      topZone.actions = [
        getAddAction(topBtn, leftBtn - 25, Icons.expand_less),
        getAddAction(topBtn, leftBtn + 5, Icons.add),
      ];
    };

    rightZone.initPos = () {
      rightZone.top = top;
      rightZone.left = right - 10;
      rightZone.width = 40;
      rightZone.height = bottom - top;

      if (rightZone.height! < 60) {
        rightZone.height = 60;
        rightZone.top = top - (60 - (bottom - top)) / 2;
      }

      double topBtn = rightZone.height! / 2;
      double leftBtn = 10;

      rightZone.actions = [
        getAddAction(topBtn - 25, leftBtn, Icons.navigate_next),
        getAddAction(topBtn + 5, leftBtn, Icons.add),
      ];
    };

    leftZone.initPos = () {
      leftZone.top = top;
      leftZone.left = left - 30;
      leftZone.width = 40;
      leftZone.height = bottom - top;

      if (leftZone.height! < 60) {
        leftZone.height = 60;
        leftZone.top = top - (60 - (bottom - top)) / 2;
      }

      double topBtn = leftZone.height! / 2;
      double leftBtn = 10;

      leftZone.actions = [
        getAddAction(topBtn - 25, leftBtn, Icons.navigate_before),
        getAddAction(topBtn + 5, leftBtn, Icons.add),
      ];
    };
  }

  Positioned getZone(ZoneDesc z) {
    z.initPos!();

    return Positioned(
        top: z.top,
        left: z.left,
        bottom: z.bottom,
        right: z.right,
        child: Container(
            width: z.width,
            height: z.height,
            //color: Colors.blueAccent.withOpacity(0.3),
            child: Stack(
              children: [
                Visibility(
                  visible: z.visibility,
                  maintainAnimation: true,
                  maintainState: true,
                  child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.fastOutSlowIn,
                      opacity: z.visibility ? 1 : 0,
                      child: Stack(
                        children: z.actions,
                      )),
                ),
                MouseRegion(
                    opaque: false,
                    onEnter: (event) {
                      setState(() {
                        z.visibility = true;
                      });
                    },
                    onExit: (event) {
                      setState(() {
                        z.visibility = false;
                      });
                    }),
              ],
            )));
  }

  @override
  Widget build(Object context) {
    List<Widget> childrenAction = [];
    childrenAction.add(getDeleteAction());
    childrenAction.add(getZone(topZone));
    childrenAction.add(getZone(bottomZone));
    childrenAction.add(getZone(rightZone));
    childrenAction.add(getZone(leftZone));

    return Visibility(
        visible: _visible, child: Stack(children: childrenAction));
  }

  Positioned getDeleteAction() {
    return Positioned(
        top: bottom,
        left: left,
        child: SizedBox(
            height: 20,
            width: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.all(0)),
              child: const Icon(Icons.delete, size: 15),
              onPressed: () {},
            )));
  }

  Positioned getAddAction(double top, double left, IconData ic) {
    return Positioned(
        top: top,
        left: left,
        child: SizedBox(
            height: 20,
            width: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.all(0)),
              child: Icon(ic, size: 15),
              onPressed: () {
                print("ddddd");
              },
            )));
  }

  // Positioned getAddRightAction(int delta, IconData ic) {
  //   return Positioned(
  //       top: delta + (bottom - top) / 2,
  //       left: 10,
  //       child: SizedBox(
  //           height: 20,
  //           width: 20,
  //           child: ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.deepOrange,
  //                 padding: const EdgeInsets.all(0)),
  //             child: Icon(ic, size: 15),
  //             onPressed: () {
  //               print("ddddd");
  //             },
  //           )));
  // }

  // Positioned getAddBottomAction(int delta, IconData ic) {
  //   return Positioned(
  //       top: 10,
  //       left: delta + (right - left) / 2,
  //       child: SizedBox(
  //           height: 20,
  //           width: 20,
  //           child: ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.deepOrange,
  //                 padding: const EdgeInsets.all(0)),
  //             child: Icon(ic, size: 15),
  //             onPressed: () {
  //               print("ddddd");
  //             },
  //           )));
  // }
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

  final GlobalKey captureKey = GlobalKey();
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
          color: Colors.deepOrange,
          dashPattern: const <double>[2, 2],
          strokeWidth: 4,
          child: widget.child);
    } else if (SelectorWidget.lastClickPath == widget.ctx.pathWidget) {
      return DottedBorder(
          color: Colors.deepOrange,
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
        duration: const Duration(milliseconds: 200),
        child: Draggable<String>(
          dragAnchorStrategy: dragAnchorStrategy,
          data: 'drag compo',
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
                child: RepaintBoundary(key: captureKey, child: getChild()),
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
      displaySelection();

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

  void displaySelection() {
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
      st.bottom = position.dy + box.size.height;
      st.top = position.dy;
      st.right = position.dx + box.size.width;
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
        captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

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
