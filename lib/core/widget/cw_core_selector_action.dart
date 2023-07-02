import 'package:flutter/material.dart';

import '../../designer/designer.dart';
import '../../widget/cw_toolkit.dart';
import 'cw_core_widget.dart';

class SelectorActionWidget extends StatefulWidget {
  SelectorActionWidget({super.key}) {
    CoreDesigner.on(CDDesignEvent.select, (arg) {
      CWWidgetCtx ctx = arg as CWWidgetCtx;
      ctx.refreshContext();
      showActionWidget(ctx.slot!.key as GlobalKey);
    });

    CoreDesigner.on(CDDesignEvent.reselect, (arg) {
      if (arg is GlobalKey) {
        showActionWidget(arg);
      }
    });
  }

  static final GlobalKey actionPanKey = GlobalKey(debugLabel: "actionPanKey");
  static final GlobalKey designerKey = GlobalKey(debugLabel: "designerKey");
  static final GlobalKey rootKey = GlobalKey(debugLabel: "rootKey");
  @override
  State<SelectorActionWidget> createState() => SelectorActionWidgetState();

  void showActionWidget(GlobalKey key) {
    // ignore: cast_nullable_to_non_nullable
    final SelectorActionWidgetState st = SelectorActionWidget
        .actionPanKey.currentState as SelectorActionWidgetState;

    // ignore: invalid_use_of_protected_member
    st.setState(() {
      final Offset position =
          CwToolkit.getPosition(key, SelectorActionWidget.designerKey);

      // ignore: cast_nullable_to_non_nullable
      final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;

      st.left = position.dx;
      st.bottom = position.dy + box.size.height;
      st.top = position.dy;
      st.right = position.dx + box.size.width;
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

class SelectorActionWidgetState extends State<SelectorActionWidget> {
  double bottom = 10;
  double left = 10;
  double top = 10;
  double right = 10;

  bool visible = false;

  ZoneDesc bottomZone = ZoneDesc();
  ZoneDesc topZone = ZoneDesc();
  ZoneDesc rightZone = ZoneDesc();
  ZoneDesc leftZone = ZoneDesc();
  ZoneDesc deleteZone = ZoneDesc();

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

    deleteZone.initPos = () {
      deleteZone.top = bottom - 10;
      deleteZone.left = left - 10;
      deleteZone.width = 40;
      deleteZone.height = 40;

      double topBtn = 10;
      double leftBtn = 10;

      deleteZone.actions = [
        getAddAction(topBtn, leftBtn, Icons.delete),
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
        child: SizedBox(
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
    childrenAction.add(getZone(deleteZone));
    childrenAction.add(getZone(topZone));
    childrenAction.add(getZone(bottomZone));
    childrenAction.add(getZone(rightZone));
    childrenAction.add(getZone(leftZone));
    childrenAction.add(AnimatedPositioned(
        duration: const Duration(milliseconds: 200),
        top: top,
        left: left,
        child: MouseRegion(
            opaque: false,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: right - left,
              height: bottom - top,
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.deepOrange)),
            ))));
    return Visibility(visible: visible, child: Stack(children: childrenAction));
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
                debugPrint("ddddd");
              },
            )));
  }
}
