import 'dart:math' as math;

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';

import '../core/widget/cw_core_widget.dart';

class ExpandInfo {
  ExpandInfo(this.title, this.body, [this.isExpanded = false]);
  bool isExpanded;
  Widget body;
  Widget title;
}

class CWExpandPanel extends CWWidget {
  int getNb() {
    return ctx.designEntity?.getInt("count", 1) ?? 1;
  }

  const CWExpandPanel({Key? key, required super.ctx}) : super(key: key);

  @override
  State<CWExpandPanel> createState() => CWExpandPanelState();

  @override
  initSlot(String path) {
    final nb = getNb();
    for (int i = 0; i < nb; i++) {
      addSlotPath('$path.Title$i', SlotConfig('${ctx.xid}Title$i'));
      addSlotPath('$path.Body$i', SlotConfig('${ctx.xid}Body$i'));
    }
  }
}

class CWExpandPanelState extends StateCW<CWExpandPanel> {
  Widget getHeader(ExpandInfo step) {
    return Container(
      color: Theme.of(context).secondaryHeaderColor,
      child: Row(
        children: [
          GestureDetector(
              onTap: () {
                setState(() {
                  ctrl.toggle();
                });
              },
              child: ExpandableIcon(
                theme: const ExpandableThemeData(
                  animationDuration: Duration(milliseconds: 100),
                  expandIcon: Icons.arrow_right,
                  collapseIcon: Icons.arrow_drop_down,
                  iconColor: Colors.white,
                  iconSize: 28.0,
                  iconRotationAngle: math.pi / 2,
                  iconPadding: EdgeInsets.only(right: 5),
                  //hasIcon: true,
                ),
              )),
          Expanded(child: step.title),
        ],
      ),
    );
  }

  final ctrl = ExpandableController(initialExpanded: true);

  @override
  Widget build(BuildContext context) {
    List<ExpandInfo> listInfo = [];
    final nb = widget.getNb();
    for (var i = 0; i < nb; i++) {
      listInfo.add(ExpandInfo(
          CWSlot(key: GlobalKey(), ctx: widget.createChildCtx("Title", i)),
          CWSlot(key: GlobalKey(), ctx: widget.createChildCtx("Body", i))));
    }

    return ExpandableNotifier(
      controller: ctrl,
      child: ScrollOnExpand(
        child: Column(
          children: listInfo.map<ExpandablePanel>((ExpandInfo step) {
            return ExpandablePanel(
              theme: const ExpandableThemeData(
                animationDuration: Duration(milliseconds: 100),
                headerAlignment: ExpandablePanelHeaderAlignment.center,
                tapHeaderToExpand: false,
                tapBodyToExpand: false,
                tapBodyToCollapse: false,
                hasIcon: false,
              ),
              header: getHeader(step),
              collapsed: Container(),
              expanded: step.body,
            );
          }).toList(),
        ),
      ),
    );
  }
}
