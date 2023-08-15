import 'dart:math' as math;

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/cw_factory.dart';

enum CWExpandAction { actions }

class CWExpandPanel extends CWWidget {
  


  const CWExpandPanel({Key? key, required super.ctx}) : super(key: key);

  static initFactory(CWWidgetCollectionBuilder c) {
    c.collection
        .addObject('CWExpandConstraint')
        .addAttr(CWExpandAction.actions.toString(), CDAttributType.CDmany);

    c.collection
        .addObject('CWAction')
        .addAttr('_idAction_', CDAttributType.CDtext)
        .addAttr('label', CDAttributType.CDtext)
        .addAttr('icon', CDAttributType.CDtext);

    c
        .addWidget("CWExpandPanel",
            (CWWidgetCtx ctx) => CWExpandPanel(key: ctx.getKey(), ctx: ctx))
        .addAttr('count', CDAttributType.CDint);
  }

  @override
  State<CWExpandPanel> createState() => CWExpandPanelState();

  int getNb() {
    return ctx.designEntity?.getInt("count", 1) ?? 1;
  }

  @override
  initSlot(String path) {
    final nb = getNb();
    for (int i = 0; i < nb; i++) {
      addSlotPath(
          '$path.Title$i',
          SlotConfig('${ctx.xid}Title$i',
              constraintEntity: 'CWExpandConstraint'));
      addSlotPath('$path.Body$i', SlotConfig('${ctx.xid}Body$i'));
    }
  }
}

class CWExpandPanelState extends StateCW<CWExpandPanel> {
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

    return LayoutBuilder(builder: (context, constraints) {
      // print('CWExpandPanelState $constraints ${widget.ctx.xid}');
      return ExpandableNotifier(
        controller: ctrl,
        child: ScrollOnExpand(
          child: Column(
            children: listInfo.map<ExpandablePanel>((ExpandInfo step) {
              Widget sizedBox = step.body;
              if (constraints.maxHeight != double.infinity) {
                sizedBox = SizedBox(
                    height: constraints.maxHeight - 28, child: step.body);
              }

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
                expanded: sizedBox,
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  Widget getHeader(ExpandInfo step) {
    CWWidgetCtx? constraint =
        widget.ctx.factory.mapConstraintByXid[step.title.ctx.xid];
    List<dynamic>? actions = constraint?.designEntity?.value[CWExpandAction.actions.toString()];

    List<Widget> header = [
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
            ),
          )),
      Expanded(child: step.title),
    ];
    if (actions != null) {
      header.add(InkResponse(
          onTapDown: (e) {
            showActions(e, actions);
          },
          child: const Icon(Icons.more_vert)));
    }

    return Container(
      color: Theme.of(context).secondaryHeaderColor,
      child: Row(
        children: header,
      ),
    );
  }

  void showActions(TapDownDetails e, List actions) {
    List<Widget> listActionWidget = [];
    for (Map<String, dynamic> action in actions) {
      listActionWidget.add(OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
            backgroundColor: Colors.black54, foregroundColor: Colors.white),
        onPressed: () {
          Navigator.pop(context);
          CWWidgetEvent ctxWE = CWWidgetEvent();
          String actionId = action["_idAction_"];
          var p = actionId.split("@");
          ctxWE.action = p[0];
          CWProvider? provider = widget.ctx.loader.factory.mapProvider[p[1]];
          if (provider != null) {
            ctxWE.provider = provider;
            ctxWE.loader = widget.ctx.loader;
            provider.doUserAction(widget.ctx, ctxWE, ctxWE.action!);
          }
        },
        icon: Icon(action["icon"] as IconData),
        label: Text(action["label"] as String),
      ));
    }

    showDialog(
        barrierColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) => Stack(children: [
              Positioned(
                  left: e.globalPosition.dx, // left coordinate
                  top: e.globalPosition.dy, // top coordinate
                  child:
                      //width: 48,
                      //     height: 48,
                      // child:SizedBox( width: 100,
                      Container(
                          decoration: BoxDecoration(
                              // shape: BoxShape.circle,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: Colors.black26)),
                          child: Column(
                            children: listActionWidget,
                          )))
            ]));
  }
}

class ExpandInfo {
  bool isExpanded;
  CWSlot body;
  CWSlot title;
  ExpandInfo(this.title, this.body, [this.isExpanded = false]);
}
