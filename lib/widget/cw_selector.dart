import 'dart:typed_data';
import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
//import 'package:defer_pointer/defer_pointer.dart';

import 'cw_builder.dart';
import 'cw_image.dart';

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
  static _SelectorWidgetState? last;
  static String lastclick = '';

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

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        //height: 100, //there should be outline/dimensions for the box.
        //Otherway, You can use positioned widget
        duration: const Duration(milliseconds: 200),
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
              onHover: (PointerHoverEvent e) {
                final bool isParent =
                    SelectorWidget.hoverPath != widget.ctx.path &&
                        SelectorWidget.hoverPath.startsWith(widget.ctx.path);

                if (!isParent &&
                    !isHover &&
                    SelectorWidget.lastclick != widget.ctx.path) {
                  print(
                      'onHover ${widget.ctx.path} ${SelectorWidget.hoverPath} $isParent =>');

                  final _SelectorWidgetState? current = SelectorWidget.last;

                  final bool remove = SelectorWidget.last != null &&
                      SelectorWidget.hoverPath != widget.ctx.path &&
                      SelectorWidget.last!.mounted;

                  setState(() {
                    isHover = true;
                    SelectorWidget.last = this;
                    SelectorWidget.hoverPath = widget.ctx.path;
                  });

                  if (remove) {
                    current?.setState(() {
                      current.isHover = false;
                    });
                  }
                }
              },
              onExit: (PointerExitEvent e) {
                print('onExit ${widget.ctx.path} =>$e');
                if (SelectorWidget.lastclick == widget.ctx.path) {
                  SelectorWidget.lastclick = '';
                }

                if (isHover) {
                  setState(() {
                    if (SelectorWidget.hoverPath == widget.ctx.path) {
                      SelectorWidget.hoverPath = '';
                      SelectorWidget.last = null;
                    }
                    isHover = false;
                  });
                }
              },
              child: Listener(
                key: widget.widgetKey,
                behavior: HitTestBehavior.opaque,
                onPointerDown: (PointerDownEvent d) async {
                  // final Size size = box.size;

                  // ignore: cast_nullable_to_non_nullable
                  final SelectorActionWidgetState st = SelectorActionWidget
                      .actionPanKey.currentState as SelectorActionWidgetState;

                  if (isHover) {
                    st.setState(() {
                      // ignore: cast_nullable_to_non_nullable
                      final RenderBox box = widget.widgetKey.currentContext!
                          .findRenderObject() as RenderBox;

                      // ignore: cast_nullable_to_non_nullable
                      final RenderBox boxDesigner = SelectorActionWidget
                          .designerKey.currentContext!
                          .findRenderObject() as RenderBox;

                      final Offset position = box.localToGlobal(Offset.zero,
                          ancestor: boxDesigner); //this is global position

                      st.left = position.dx;
                      st.top = position.dy + box.size.height;
                      st._visible = true;
                    });
                  }

                  if (isHover) {
                    String prop = 'no CWWidget';

                    CWWidget? w = widget.ctx.factory.mapWidget[widget.ctx.xid];
                    if (w != null) {
                      prop = w.entity?.value.toString() ?? 'no prop';
                    }

                    _capturePng();

                    print(
                        'Clicked gesture ${widget.ctx.path} ${d.buttons} ${widget.ctx.xid} ${prop}');

                    if (d.buttons == 2) {
                      // ignore: cast_nullable_to_non_nullable
                      final RenderBox box = widget.widgetKey.currentContext!
                          .findRenderObject() as RenderBox;

                      // ignore: cast_nullable_to_non_nullable
                      final RenderBox rootBox = SelectorActionWidget
                          .rootKey.currentContext!
                          .findRenderObject() as RenderBox;

                      final Offset position = box.localToGlobal(Offset.zero,
                          ancestor: rootBox); //this is global position

                      _showPopupMenu(Offset(position.dx + d.localPosition.dx,
                          position.dy + d.localPosition.dy));
                    }
                    setState(() {
                      //isHover = false;
                      if (SelectorWidget.lastclick == widget.ctx.path) {
                        // HoveringWidget.lastclick = '';
                      } else {
                        SelectorWidget.lastclick = widget.ctx.path;
                      }
                    });
                  }
                },
                child: RepaintBoundary(key: paintKey, child: getChild()),
              )),
        ));
  }

  Widget getChild() {
    if (isHover && SelectorWidget.lastclick == widget.ctx.path) {
      return DottedBorder(
          color: Colors.blue,
          dashPattern: const <double>[8, 8],
          strokeWidth: 4,
          child: widget.child);
    } else {
      return widget.child;
    }
  }

  void _showPopupMenu(Offset offset) {
    final double left = offset.dx;
    final double top = offset.dy;

    _capturePng();

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
        print('+++++++++++++++++++++++++ $value');
      }
    });
  }

  Future<Uint8List?> _capturePng() async {
    print('inside');
    RenderRepaintBoundary? boundary =
        paintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    /// convert boundary to image
    final image = await boundary!.toImage(pixelRatio: 0.5);
    final byteData = await image?.toByteData(format: ImageByteFormat.png);
    final imageBytes = byteData?.buffer.asUint8List();

    Widget wi = Image.memory(imageBytes!);

    CwImageState.wi = wi;

    print(
        '+++++++++++++++++++++++ ${image.toString()} ${imageBytes?.length ?? 0}');
  }
}