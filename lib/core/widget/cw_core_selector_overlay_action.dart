import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/selector_manager.dart';

import '../../designer/action_manager.dart';
import '../../designer/designer.dart';
import '../../designer/builder/prop_builder.dart';
import '../../widget/cw_toolkit.dart';
import '../data/core_data.dart';
import 'cw_core_loader.dart';

final log = Logger('SelectorActionWidget');

class SelectorActionWidget extends StatefulWidget {
  const SelectorActionWidget({super.key});

  static final GlobalKey actionPanKey = GlobalKey(debugLabel: 'actionPanKey');
  static final GlobalKey designerKey = GlobalKey(debugLabel: 'designerKey');
  static final GlobalKey scaleKeyMin = GlobalKey(debugLabel: 'scaleKey1');
  static final GlobalKey scaleKey2 = GlobalKey(debugLabel: 'scaleKey2');
  static final GlobalKey scaleKeyMax = GlobalKey(debugLabel: 'scaleKeyMax');
  // static final GlobalKey rootKey = GlobalKey(debugLabel: "rootKey");

  static String? pathLock;

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

  static void showActionWidget(CWWidgetInfoSelector info) {
    // ignore: cast_nullable_to_non_nullable
    final SelectorActionWidgetState stateSelectorAction = SelectorActionWidget
        .actionPanKey.currentState as SelectorActionWidgetState;

    if (info.slotKey == null) {
      debugPrint('showActionWidget none');
      return;
    }

    // ignore: invalid_use_of_protected_member
    stateSelectorAction.setState(() {
      setPosition(info.slotKey!, stateSelectorAction.recSlot);
      stateSelectorAction.visibleContent = false;

      if (info.contentKey != null) {
        setPosition(info.contentKey!, stateSelectorAction.recContent);
        stateSelectorAction.visibleContent =
            !stateSelectorAction.recContent.equals(stateSelectorAction.recSlot);
      }

      stateSelectorAction.visible = true;
    });
  }

  static void setPosition(GlobalKey selectedKey, CWRec r) {
    final Offset position =
        CwToolkit.getPosition(selectedKey, SelectorActionWidget.designerKey);

    Offset positionRefMin = CwToolkit.getPosition(
        SelectorActionWidget.scaleKeyMin, CoreDesigner.of().designerKey);
    Offset positionRef100 = CwToolkit.getPosition(
        SelectorActionWidget.scaleKey2, CoreDesigner.of().designerKey);
    Offset positionRefMax = CwToolkit.getPosition(
        SelectorActionWidget.scaleKeyMax, CoreDesigner.of().designerKey);

    double previewPixelRatio = (positionRef100.dx - positionRefMin.dx) / 100;

    final RenderBox box =
        selectedKey.currentContext!.findRenderObject() as RenderBox;

    r.left = position.dx * previewPixelRatio + positionRefMin.dx;
    r.bottom = position.dy * previewPixelRatio +
        positionRefMin.dy +
        box.size.height * previewPixelRatio;
    r.top = position.dy * previewPixelRatio + positionRefMin.dy;
    r.right = position.dx * previewPixelRatio +
        positionRefMin.dx +
        box.size.width * previewPixelRatio;

    if (r.top < positionRefMin.dy) {
      r.top = positionRefMin.dy;
    }
    if (r.bottom > positionRefMax.dy) {
      r.bottom = positionRefMax.dy;
    }
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

enum DesignAction {
  delete,
  size,
  addTop,
  addBottom,
  moveBottom,
  moveTop,
  addRight,
  addLeft,
  moveRight,
  moveLeft,
  none
}

class CWRec {
  double bottom = 10;
  double left = 10;
  double top = 10;
  double right = 10;

  bool equals(CWRec r) {
    return r.bottom == bottom &&
        r.left == left &&
        r.top == top &&
        r.right == right;
  }
}

class SelectorActionWidgetState extends State<SelectorActionWidget> {
  CWRec recSlot = CWRec();
  CWRec recContent = CWRec();

  bool visibleContent = false;
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
      log.fine('init event listener');
      isInitiaziled = true;
      onPreviewFct = CoreDesigner.on(CDDesignEvent.preview, (arg) {
        isPreviewMode = arg as bool;
        setState(() {
          visible = !isPreviewMode;
        });
      });
    }

    //////////////////////////////////////////////////////////////////////////
    bottomZone.initPos = (CWRec r) {
      bottomZone.top = r.bottom - 10;
      bottomZone.left = r.left;
      bottomZone.width = r.right - r.left;
      bottomZone.height = 40;

      double topBtn = 10;
      double leftBtn = bottomZone.width! / 2;

      bottomZone.actions = [
        getAddAction(
            topBtn, leftBtn - 25, Icons.expand_more, DesignAction.moveBottom),
        getAddAction(topBtn, leftBtn + 5, Icons.add, DesignAction.addBottom),
      ];
    };

    topZone.initPos = (CWRec r) {
      topZone.top = r.top - 30;
      topZone.left = r.left;
      topZone.width = r.right - r.left;
      topZone.height = 40;
      double topBtn = 10;
      double leftBtn = topZone.width! / 2;
      topZone.actions = [
        getAddAction(
            topBtn, leftBtn - 25, Icons.expand_less, DesignAction.moveTop),
        getAddAction(topBtn, leftBtn + 5, Icons.add, DesignAction.addTop),
      ];
    };

    rightZone.initPos = (CWRec r) {
      rightZone.top = r.top;
      rightZone.left = r.right - 10;
      rightZone.width = 40;
      rightZone.height = r.bottom - r.top;

      if (rightZone.height! < 60) {
        rightZone.height = 60;
        rightZone.top = r.top - (60 - (r.bottom - r.top)) / 2;
      }

      double topBtn = rightZone.height! / 2;
      double leftBtn = 10;

      rightZone.actions = [
        getAddAction(
            topBtn - 25, leftBtn, Icons.navigate_next, DesignAction.moveRight),
        getAddAction(topBtn + 5, leftBtn, Icons.add, DesignAction.addRight),
      ];
    };

    leftZone.initPos = (CWRec r) {
      leftZone.top = r.top;
      leftZone.left = r.left - 30;
      leftZone.width = 40;
      leftZone.height = r.bottom - r.top;

      if (leftZone.height! < 60) {
        leftZone.height = 60;
        leftZone.top = r.top - (60 - (r.bottom - r.top)) / 2;
      }

      double topBtn = leftZone.height! / 2;
      double leftBtn = 10;

      leftZone.actions = [
        getAddAction(
            topBtn - 25, leftBtn, Icons.navigate_before, DesignAction.moveLeft),
        getAddAction(topBtn + 5, leftBtn, Icons.add, DesignAction.addLeft),
      ];
    };

    deleteZone.initPos = (CWRec r) {
      deleteZone.top = r.bottom - 20;
      deleteZone.left = r.left - 20;
      deleteZone.width = 60;
      deleteZone.height = 60;

      double topBtn = 15;
      double leftBtn = 5;

      deleteZone.actions = [
        getAddAction(topBtn, leftBtn, Icons.delete, DesignAction.delete),
      ];
    };

    sizeZone.initPos = (CWRec r) {
      sizeZone.top = r.bottom - 10;
      sizeZone.left = r.right - 30;
      sizeZone.width = 40;
      sizeZone.height = 40;

      double topBtn = 10;
      double leftBtn = 10;

      sizeZone.actions = [
        getAddDrag(topBtn, leftBtn, Icons.open_in_full, DesignAction.size),
      ];
    };
  }

  ///////////////////////////////////////////////////////////////////////////////

  Positioned getZone(ZoneDesc z, CWRec r) {
    z.initPos!(r);

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
    childrenAction.add(getZone(deleteZone, recSlot));
    childrenAction.add(getZone(sizeZone, recSlot));
    childrenAction.add(getZone(topZone, recSlot));
    childrenAction.add(getZone(bottomZone, recSlot));
    childrenAction.add(getZone(rightZone, recSlot));
    childrenAction.add(getZone(leftZone, recSlot));
    childrenAction
        .add(BoxSelected(key: boxkey, rec: recSlot, mode: CWModeBox.slot));

    if (visibleContent) {
      childrenAction.add(BoxSelected(
        rec: recContent,
        mode: CWModeBox.content,
      ));
    }

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
              box.changeSize(
                  recSlot.bottom - recSlot.top, recSlot.right - recSlot.left);
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
      DesignActionManager().doDelete();
    } else if (action == DesignAction.addBottom) {
      DesignActionManager().addBottom();
    } else if (action == DesignAction.addTop) {
      DesignActionManager().addTop();
    } else if (action == DesignAction.moveBottom) {
      DesignActionManager().moveBottom();
    } else if (action == DesignAction.moveTop) {
      DesignActionManager().moveTop();
    } else if (action == DesignAction.addRight) {
      DesignActionManager().addRight();
    } else if (action == DesignAction.addLeft) {
      DesignActionManager().addLeft();
    } else if (action == DesignAction.moveRight) {
      DesignActionManager().moveRight();
    } else if (action == DesignAction.moveLeft) {
      DesignActionManager().moveLeft();
    }
  }
}

enum CWModeBox { slot, content }

// ignore: must_be_immutable
class BoxSelected extends StatefulWidget {
  BoxSelected({super.key, required this.rec, required this.mode});

  CWRec rec;
  CWModeBox mode;

  Size getSize() {
    return Size(rec.right - rec.left, rec.bottom - rec.top);
  }

  @override
  State<BoxSelected> createState() {
    return BoxSelectedState();
  }
}

class BoxSelectedState extends State<BoxSelected> {
  void changeSize(double h, double w) {
    setState(() {
      widget.rec.bottom = h + widget.rec.top;
      widget.rec.right = w + widget.rec.left;
    });
  }

  void addSize(double h, double w) {
    setState(() {
      if (h > 0 || widget.rec.bottom + h > widget.rec.top + 5) {
        widget.rec.bottom = h + widget.rec.bottom;
      }
      if (w > 0 || widget.rec.right + w >= widget.rec.left + 5) {
        widget.rec.right = w + widget.rec.right;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
        duration: Duration(
            milliseconds: (SelectorActionWidgetState.dragInProgess ? 1 : 200)),
        top: widget.rec.top,
        left: widget.rec.left,
        child: MouseRegion(
            opaque: false,
            child: AnimatedContainer(
              duration: Duration(
                  milliseconds:
                      (SelectorActionWidgetState.dragInProgess ? 1 : 200)),
              width: widget.rec.right - widget.rec.left,
              height: widget.rec.bottom - widget.rec.top,
              decoration: BoxDecoration(
                  border: Border.all(
                      color: widget.mode == CWModeBox.slot
                          ? Colors.deepOrange
                          : Colors.lightBlue)),
            )));
  }
}
