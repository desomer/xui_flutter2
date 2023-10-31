import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/selector_manager.dart';

import '../../designer/action_manager.dart';
import '../../designer/designer.dart';
import '../../designer/builder/prop_builder.dart';
import '../../widget/cw_toolkit.dart';
import '../data/core_data.dart';
import 'cw_core_loader.dart';
import 'cw_core_slot.dart';
import 'cw_core_widget.dart';

class SelectorActionWidget extends StatefulWidget {
  const SelectorActionWidget({super.key});

  static final GlobalKey actionPanKey = GlobalKey(debugLabel: 'actionPanKey');
  static final GlobalKey designerKey = GlobalKey(debugLabel: 'designerKey');
  static final GlobalKey scaleKeyMin = GlobalKey(debugLabel: 'scaleKey1');
  static final GlobalKey scaleKey2 = GlobalKey(debugLabel: 'scaleKey2');
  static final GlobalKey scaleKeyMax = GlobalKey(debugLabel: 'scaleKeyMax');
  // static final GlobalKey rootKey = GlobalKey(debugLabel: "rootKey");

  @override
  State<SelectorActionWidget> createState() => SelectorActionWidgetState();

  static void removeActionWidget() {
    final SelectorActionWidgetState st = SelectorActionWidget
        .actionPanKey.currentState as SelectorActionWidgetState;
    // ignore: invalid_use_of_protected_member
    st.setState(() {
      CoreDesignerSelector.of().unselect();
      st.visible = false;
    });
  }

  static void showActionWidget(GlobalKey key) {
    // ignore: cast_nullable_to_non_nullable
    final SelectorActionWidgetState st = SelectorActionWidget
        .actionPanKey.currentState as SelectorActionWidgetState;

    if (key.currentContext == null) {
      debugPrint('showActionWidget none');
      return;
    }

    // ignore: invalid_use_of_protected_member
    st.setState(() {
      final Offset position =
          CwToolkit.getPosition(key, SelectorActionWidget.designerKey);

      Offset positionRefMin = CwToolkit.getPosition(
          SelectorActionWidget.scaleKeyMin, CoreDesigner.of().designerKey);
      Offset positionRef100 = CwToolkit.getPosition(
          SelectorActionWidget.scaleKey2, CoreDesigner.of().designerKey);
      Offset positionRefMax = CwToolkit.getPosition(
          SelectorActionWidget.scaleKeyMax, CoreDesigner.of().designerKey);

      double previewPixelRatio = (positionRef100.dx - positionRefMin.dx) / 100;
      //double p2 = positionRef2.dy - positionRefMin.dy;
      //print("showActionWidget $p1 $p2");

      // ignore: cast_nullable_to_non_nullable
      final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;

      st.gLeft = position.dx * previewPixelRatio + positionRefMin.dx;
      st.gBottom = position.dy * previewPixelRatio +
          positionRefMin.dy +
          box.size.height * previewPixelRatio;
      st.gTop = position.dy * previewPixelRatio + positionRefMin.dy;
      st.gRight = position.dx * previewPixelRatio +
          positionRefMin.dx +
          box.size.width * previewPixelRatio;

      if (st.gTop < positionRefMin.dy) st.gTop = positionRefMin.dy;
      if (st.gBottom > positionRefMax.dy) st.gBottom = positionRefMax.dy;

      st.visible = true;
    });
  }
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

enum DesignAction { delete, size, none }

class SelectorActionWidgetState extends State<SelectorActionWidget> {
  double gBottom = 10;
  double gLeft = 10;
  double gTop = 10;
  double gRight = 10;

  bool visible = false;

  ZoneDesc bottomZone = ZoneDesc();
  ZoneDesc topZone = ZoneDesc();
  ZoneDesc rightZone = ZoneDesc();
  ZoneDesc leftZone = ZoneDesc();
  ZoneDesc deleteZone = ZoneDesc();
  ZoneDesc sizeZone = ZoneDesc();

  @override
  void dispose() {
    super.dispose();

    isInitiaziled = false;
    CoreDesigner.removeListener(CDDesignEvent.preview, onPreviewFct!);
  }

  bool isInitiaziled = false;
  bool isPreviewMode = false;
  Function(dynamic)? onPreviewFct;

  @override
  void initState() {
    super.initState();

    if (!isInitiaziled) {
      isInitiaziled = true;
      onPreviewFct = CoreDesigner.on(CDDesignEvent.preview, (arg) {
        isPreviewMode = arg as bool;
        setState(() {
          visible = !isPreviewMode;
        });
      });
    }

    bottomZone.initPos = () {
      bottomZone.top = gBottom - 10;
      bottomZone.left = gLeft;
      bottomZone.width = gRight - gLeft;
      bottomZone.height = 40;

      double topBtn = 10;
      double leftBtn = (gRight - gLeft) / 2;

      bottomZone.actions = [
        getAddAction(
            topBtn, leftBtn - 25, Icons.expand_more, DesignAction.none),
        getAddAction(topBtn, leftBtn + 5, Icons.add, DesignAction.none),
      ];
    };

    topZone.initPos = () {
      topZone.top = gTop - 30;
      topZone.left = gLeft;
      topZone.width = gRight - gLeft;
      topZone.height = 40;
      double topBtn = 10;
      double leftBtn = (gRight - gLeft) / 2;
      topZone.actions = [
        getAddAction(
            topBtn, leftBtn - 25, Icons.expand_less, DesignAction.none),
        getAddAction(topBtn, leftBtn + 5, Icons.add, DesignAction.none),
      ];
    };

    rightZone.initPos = () {
      rightZone.top = gTop;
      rightZone.left = gRight - 10;
      rightZone.width = 40;
      rightZone.height = gBottom - gTop;

      if (rightZone.height! < 60) {
        rightZone.height = 60;
        rightZone.top = gTop - (60 - (gBottom - gTop)) / 2;
      }

      double topBtn = rightZone.height! / 2;
      double leftBtn = 10;

      rightZone.actions = [
        getAddAction(
            topBtn - 25, leftBtn, Icons.navigate_next, DesignAction.none),
        getAddAction(topBtn + 5, leftBtn, Icons.add, DesignAction.none),
      ];
    };

    leftZone.initPos = () {
      leftZone.top = gTop;
      leftZone.left = gLeft - 30;
      leftZone.width = 40;
      leftZone.height = gBottom - gTop;

      if (leftZone.height! < 60) {
        leftZone.height = 60;
        leftZone.top = gTop - (60 - (gBottom - gTop)) / 2;
      }

      double topBtn = leftZone.height! / 2;
      double leftBtn = 10;

      leftZone.actions = [
        getAddAction(
            topBtn - 25, leftBtn, Icons.navigate_before, DesignAction.none),
        getAddAction(topBtn + 5, leftBtn, Icons.add, DesignAction.none),
      ];
    };

    deleteZone.initPos = () {
      deleteZone.top = gBottom - 10;
      deleteZone.left = gLeft - 10;
      deleteZone.width = 40;
      deleteZone.height = 40;

      double topBtn = 10;
      double leftBtn = 10;

      deleteZone.actions = [
        getAddAction(topBtn, leftBtn, Icons.delete, DesignAction.delete),
      ];
    };

    sizeZone.initPos = () {
      sizeZone.top = gBottom - 10;
      sizeZone.left = gRight - 30;
      sizeZone.width = 40;
      sizeZone.height = 40;

      double topBtn = 10;
      double leftBtn = 10;

      sizeZone.actions = [
        getAddDrag(topBtn, leftBtn, Icons.open_in_full, DesignAction.size),
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
        // ignore: sized_box_for_whitespace
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
                      if (!dragInProgess) {
                        setState(() {
                          z.visibility = true;
                        });
                      }
                    },
                    onExit: (event) {
                      if (!dragInProgess) {
                        setState(() {
                          z.visibility = false;
                        });
                      }
                    }),
              ],
            )));
  }

  @override
  Widget build(Object context) {
    List<Widget> childrenAction = [];
    childrenAction.add(getZone(deleteZone));
    childrenAction.add(getZone(sizeZone));
    childrenAction.add(getZone(topZone));
    childrenAction.add(getZone(bottomZone));
    childrenAction.add(getZone(rightZone));
    childrenAction.add(getZone(leftZone));
    childrenAction.add(BoxSelected(
        key: boxkey, top: gTop, left: gLeft, right: gRight, bottom: gBottom));
    return Visibility(
        visible: visible && !isPreviewMode,
        child: Stack(children: childrenAction));
  }

  GlobalKey boxkey = GlobalKey();

  Positioned getAddAction(
      double top, double left, IconData ic, DesignAction action) {
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
                debugPrint('doAction $action');
                doAction(action);
              },
            )));
  }

  static bool dragInProgess = false;

  Positioned getAddDrag(
      double top, double left, IconData ic, DesignAction action) {
    return Positioned(
        top: top,
        left: left,
        child: Draggable(
            data: 'ok',
            onDragUpdate: (details) {
              dragInProgess = true;
              BoxSelectedState box = boxkey.currentState as BoxSelectedState;
              box.addSize(details.delta.dy, details.delta.dx);

              var selected = CoreDesignerSelector.of().getSelectedSlotContext();

              DesignCtx aCtx = DesignCtx().forDesign(selected!);

              Offset positionRefMin = CwToolkit.getPosition(
                  SelectorActionWidget.scaleKeyMin,
                  CoreDesigner.of().designerKey);
              Offset positionRef100 = CwToolkit.getPosition(
                  SelectorActionWidget.scaleKey2,
                  CoreDesigner.of().designerKey);

              double previewPixelRatio =
                  (positionRef100.dx - positionRefMin.dx) / 100;

              CoreDataEntity prop =
                  PropBuilder.preparePropChange(selected.loader, aCtx);
              double h = box.widget.getSize().height / previewPixelRatio;
              prop.value['height'] = h.toInt();

              double w = box.widget.getSize().width / previewPixelRatio;
              prop.value['width'] = w.toInt();              

              if (bottomZone.visibility) {
                final SelectorActionWidgetState st = SelectorActionWidget
                    .actionPanKey.currentState as SelectorActionWidgetState;
                st.setState(() {
                  bottomZone.visibility = false;
                  sizeZone.visibility = false;
                });
              }

              CoreDesignerSelector.of()
                  .getSelectedSlotContext()!
                  .getParentCWWidget()
                  ?.repaint();
            },
            onDraggableCanceled: (velocity, offset) {
              dragInProgess = false;
              BoxSelectedState box = boxkey.currentState as BoxSelectedState;
              box.changeSize(gBottom - gTop, gRight - gLeft);
              CoreDesigner.emit(CDDesignEvent.reselect, null);
            },
            feedback: SizedBox(
                height: 20,
                width: 20,
                child: Container(
                  color: Colors.deepOrange,
                )),
            child: SizedBox(
                height: 20,
                width: 20,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.all(0)),
                  child: Icon(ic, size: 15),
                  onPressed: () {
                    debugPrint('doAction $action');
                    doAction(action);
                  },
                ))));
  }

  void doAction(DesignAction action) {
    if (action == DesignAction.delete) {
      CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedWidgetContext();
      if (ctx != null) {
        DesignActionManager().doDelete(ctx);
      } else {
        CWWidgetCtx? ctx = CoreDesignerSelector.of().getSelectedSlotContext();
        debugPrint('delete slot ${ctx?.xid}');
        SlotAction? slotAction = ctx?.inSlot?.slotAction;
        if (slotAction!=null)
        {
          slotAction.doDelete(ctx!);
        }
      }
    }
  }
}

// ignore: must_be_immutable
class BoxSelected extends StatefulWidget {
  BoxSelected({
    super.key,
    required this.top,
    required this.left,
    required this.right,
    required this.bottom,
  });

  double top;
  double left;
  double right;
  double bottom;

  Size getSize() {
    return Size(right - left, bottom - top);
  }

  @override
  State<BoxSelected> createState() {
    return BoxSelectedState();
  }
}

class BoxSelectedState extends State<BoxSelected> {
  void changeSize(double h, double w) {
    setState(() {
      widget.bottom = h + widget.top;
      widget.right = w + widget.left;
    });
  }

  void addSize(double h, double w) {
    setState(() {
      if (h > 0 || widget.bottom + h > widget.top + 5) {
        widget.bottom = h + widget.bottom;
      }
      if (w > 0 || widget.right + w >= widget.left + 5) {
        widget.right = w + widget.right;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
        duration: Duration(
            milliseconds: (SelectorActionWidgetState.dragInProgess ? 1 : 200)),
        top: widget.top,
        left: widget.left,
        child: MouseRegion(
            opaque: false,
            child: AnimatedContainer(
              duration: Duration(
                  milliseconds:
                      (SelectorActionWidgetState.dragInProgess ? 1 : 200)),
              width: widget.right - widget.left,
              height: widget.bottom - widget.top,
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.deepOrange)),
            )));
  }
}
