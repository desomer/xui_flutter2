import 'dart:math' as math;

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_slot.dart';
import 'package:xui_flutter/widget/cw_action.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_widget.dart';
import '../core/widget/cw_factory.dart';
import '../designer/help/widget_no_visible_on_resize.dart';

enum CWExpandAction { actions, btnHeader }

class CWExpandPanel extends CWWidget {
  const CWExpandPanel({super.key, required super.ctx});

  static void initFactory(CWWidgetCollectionBuilder c) {
    c.collection
        .addObject('CWExpandConstraint')
        .addAttr(CWExpandAction.actions.toString(), CDAttributType.many)
        .addAttr(CWExpandAction.btnHeader.toString(), CDAttributType.many);

    c.collection
        .addObject('CWExpandAction')
        .addAttr('_idAction_', CDAttributType.text)
        .addAttr('label', CDAttributType.text)
        .addAttr('icon', CDAttributType.text);

    c
        .addWidget('CWExpandPanel',
            (CWWidgetCtx ctx) => CWExpandPanel(key: ctx.getKey(), ctx: ctx))
        .addAttr(iDCount, CDAttributType.int);
  }

  @override
  State<CWExpandPanel> createState() => CWExpandPanelState();

  int getNb() {
    return ctx.designEntity?.getInt(iDCount, 1) ?? 1;
  }

  @override
  void initSlot(String path, ModeParseSlot mode) {
    final nb = getNb();
    for (int i = 0; i < nb; i++) {
      addSlotPath(
          '$path.Title$i',
          SlotConfig(XidBuilder(tag:'Title', idx: i), ctx.xid,
              constraintEntity: 'CWExpandConstraint'), mode);
      addSlotPath('$path.Body$i', SlotConfig(XidBuilder(tag:'Body', idx: i), ctx.xid), mode);
    }
  }
}

class CWExpandPanelState extends StateCW<CWExpandPanel> with CWActionManager {
  final ctrl = ExpandableController(initialExpanded: true);
  final debouncer = Debouncer(milliseconds: 200);
  int timeResize = 0;
  double lastHeight = 0;

  @override
  Widget build(BuildContext context) {
    List<ExpandInfo> listInfo = [];
    final nb = widget.getNb();
    for (var i = 0; i < nb; i++) {
      listInfo.add(ExpandInfo(
          CWSlot(
              type: 'title',
              key: GlobalKey(),
              ctx: widget.createChildCtx(widget.ctx, 'Title', i)),
          CWSlot(
              type: 'body',
              key: GlobalKey(),
              ctx: widget.createChildCtx(widget.ctx, 'Body', i))));
    }

    return LayoutBuilder(builder: (context, constraints) {
      // print('CWExpandPanelState $constraints ${widget.ctx.xid}');
      if (lastHeight != constraints.maxHeight) {
        lastHeight = constraints.maxHeight;
        timeResize = DateTime.now().millisecondsSinceEpoch;
      }
      bool display = debouncer.mustVisible(this, timeResize);

      return ExpandableNotifier(
        controller: ctrl,
        child: ScrollOnExpand(
          theme: const ExpandableThemeData(
              scrollAnimationDuration: Duration(milliseconds: 500)),
          child: Column(
            children: listInfo.map<Widget>((ExpandInfo step) {
              Widget sizedBox = step.body;
              if (constraints.maxHeight != double.infinity) {
                sizedBox = SizedBox(
                    height: constraints.maxHeight - 28, child: step.body);
              }

              return display
                  ? ExpandablePanel(
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
                    )
                  : Container();
            }).toList(),
          ),
        ),
      );
    });
  }

  Widget getHeader(ExpandInfo step) {
    CWWidgetCtx? constraint =
        widget.ctx.factory.mapConstraintByXid[step.title.ctx.xid];
    List<dynamic>? actions =
        constraint?.designEntity?.value[CWExpandAction.actions.toString()];
    List<dynamic>? btnHeader =
        constraint?.designEntity?.value[CWExpandAction.btnHeader.toString()];

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
    if (btnHeader != null) {
      for (Map<String, dynamic> btn in btnHeader) {
        header.add(Padding(
            padding: const EdgeInsets.fromLTRB(0,0,10,0),
            child: InkResponse(
                onTapDown: (e) {
                  doAction(context, widget, btn);
                },
                child: Icon(
                    size: 18,
                    color: Theme.of(context).hintColor,
                    btn['icon'] as IconData))));
      }
    }
    if (actions != null) {
      header.add(InkResponse(
          onTapDown: (e) {
            showActions(e, actions, context);
          },
          child: const Icon(Icons.more_vert)));
    }

    return Container(
      color: Theme.of(context).highlightColor,
      child: Row(
        children: header,
      ),
    );
  }

  void showActions(TapDownDetails e, List actions, BuildContext context) {
    List<Widget> listActionWidget = [];
    for (Map<String, dynamic> action in actions) {
      listActionWidget.add(OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
            backgroundColor: Colors.black54, foregroundColor: Colors.white),
        onPressed: () {
          Navigator.pop(context);
          doAction(context, widget, action);
        },
        icon: Icon(action['icon'] as IconData),
        label: Text(action['label'] as String),
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

  // void doAction(Map<String, dynamic> properties) {
  //   CWWidgetEvent ctxWE = CWWidgetEvent();
  //   String actionId = properties['_idAction_'];
  //   var p = actionId.split('@');
  //   ctxWE.action = p[0];
  //   CWProvider? provider = widget.ctx.loader.factory.mapProvider[p[1]];
  //   if (provider != null) {
  //     ctxWE.provider = provider;
  //     ctxWE.loader = widget.ctx.loader;
  //     provider.doUserAction(widget.ctx, ctxWE, ctxWE.action!);
  //   }
  // }
}

class ExpandInfo {
  bool isExpanded;
  CWSlot body;
  CWSlot title;
  ExpandInfo(this.title, this.body, [this.isExpanded = false]);
}
