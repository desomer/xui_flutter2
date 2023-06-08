import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
//import 'package:defer_pointer/defer_pointer.dart';

import 'cw_builder.dart';
import 'cw_image.dart';
import 'cw_toolkit.dart';

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
  SelectorWidget({super.key, required this.child, required this.ctx}) {
    print("NEWNEWNEWNEWNEWNEW");
  }

  final GlobalKey widgetKey = GlobalKey();
  final Widget child;
  CWWidgetCtx ctx;

  static String hoverPath = '';
  // ignore: library_private_types_in_public_api
  static _SelectorWidgetState? lastStateOver;

  static String lastclick = '';
  static _SelectorWidgetState? lastStateClick;

  @override
  State<SelectorWidget> createState() => _SelectorWidgetState();
}

class _SelectorWidgetState extends State<SelectorWidget> {
  bool isHover = false;

  Offset dragAnchorStrategy(
      Draggable<Object> d, BuildContext context, Offset point) {
    return Offset(d.feedbackOffset.dx + 25, d.feedbackOffset.dy + 30);
  }

  final GlobalKey paintKey = GlobalKey();

  // WidgetsToImageController controller = WidgetsToImageController();
  // // to save image bytes of widget
  // Uint8List? bytes;

  bool menuIsOpen = false;
  final GlobalKey InkWellKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return InkWell(
        key: InkWellKey,

        //height: 100, //there should be outline/dimensions for the box.
        //Otherway, You can use positioned widget
        //duration: const Duration(milliseconds: 200),
        // margin: EdgeInsets.only(
        //     right: isHover ? 2 : 0.0,
        //     left: isHover ? 2 : 0,
        //     top: isHover ? 2 : 0.0,
        //     bottom: isHover ? 2 : 0),
        child: Draggable<String>(
          dragAnchorStrategy: dragAnchorStrategy,
          data: 'ok',
          feedback: const SizedBox(
            height: 50.0,
            width: 50.0,
            child: Icon(Icons.circle),
          ),
          //child:
          //  Material(
          //     color: Colors.transparent,
          child: MouseRegion(
              onHover: onHover,
              onExit: onExit,
              child: Listener(
                key: widget.widgetKey,
                behavior: HitTestBehavior.opaque,
                onPointerDown: (PointerDownEvent d) {
                  if (menuIsOpen) return;

                  // final Size size = box.size;

                  if (isHover) {
                    showActionWidget();
                  }

                  if (isHover) {
                    String prop = 'no CWWidget';

                    CWWidget? w = widget.ctx.factory.mapWidget[widget.ctx.xid];
                    if (w != null) {
                      prop = w.entity?.value.toString() ?? 'no prop';
                    }

                    _capturePng();

                    debugPrint(
                        'Clicked gesture ${widget.ctx.path} ${d.buttons} ${widget.ctx.xid} $prop');

                    if (SelectorWidget.lastclick != widget.ctx.path) {
                      setState(() {
                        print("setlection ${widget.ctx.path}");
                        
                        SelectorWidget.lastclick = widget.ctx.path;

                        if (SelectorWidget.lastStateClick!=null && SelectorWidget.lastStateClick!.mounted)
                        {
                          SelectorWidget.lastStateClick?.setState(() {
                            
                          });
                        }

                        SelectorWidget.lastStateClick = this;
                      });
                    }

                    if (d.buttons == 2) {
                      final Offset position = CwToolkit.getPosition(
                          widget.widgetKey, SelectorActionWidget.rootKey);

                      menuIsOpen = true;
                      Future.delayed(const Duration(milliseconds: 200), () {
                        menuIsOpen = false;
                      });

                      _showPopupMenu(Offset(
                          position.dx + d.localPosition.dx + 10,
                          position.dy + d.localPosition.dy + 10));
                    }
                  }
                },
                child: RepaintBoundary(key: paintKey, child: getChild()),
              )),
        ));
  }

  void onExit(PointerExitEvent e) {
    if (menuIsOpen) return;

    // if (SelectorWidget.lastclick == widget.ctx.path) {
    //   SelectorWidget.lastclick = '';
    // }

    if (isHover) {
      setState(() {
        if (SelectorWidget.hoverPath == widget.ctx.path) {
          debugPrint('onExit hover ${widget.ctx.path} =>$e');
          SelectorWidget.hoverPath = '';
          SelectorWidget.lastStateOver = null;
        }
        isHover = false;
      });
    }
  }

  void onHover(PointerHoverEvent e) {
    final bool isParent = SelectorWidget.hoverPath != widget.ctx.path &&
        SelectorWidget.hoverPath.startsWith(widget.ctx.path);

    if (!isParent &&
        !isHover /* && SelectorWidget.lastclick != widget.ctx.path*/) {
      debugPrint(
          'onHover ${widget.ctx.path} ${SelectorWidget.hoverPath} $isParent =>');

      removeLastOver();

      setState(() {
        isHover = true;
        SelectorWidget.lastStateOver = this;
        SelectorWidget.hoverPath = widget.ctx.path;
      });
    }
  }

  void removeLastClick() {
    final _SelectorWidgetState? current = SelectorWidget.lastStateClick;

    final bool remove = SelectorWidget.lastStateClick != null &&
        SelectorWidget.lastclick != widget.ctx.path &&
        SelectorWidget.lastStateClick!.mounted;

    if (remove) {
      current?.setState(() {
      });
    }
  }

  void removeLastOver() {
    final _SelectorWidgetState? current = SelectorWidget.lastStateOver;

    final bool remove = SelectorWidget.lastStateOver != null &&
        SelectorWidget.hoverPath != widget.ctx.path &&
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

  Widget getChild() {
    if (SelectorWidget.lastclick == widget.ctx.path) {
      return DottedBorder(
          color: Colors.blue,
          dashPattern: const <double>[8, 8],
          strokeWidth: 4,
          child: widget.child);
    } else {
      return widget.child;
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
        PopupMenuItem(
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
        debugPrint('kkkkkkkkkkkkkk click $value');
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
        '+++++++++++++++++++++++ ${image.toString()} ${imageBytes.length}');
  }
}
