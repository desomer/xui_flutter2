import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class AttributDesc {
  static List<Widget> get getListAttr {
    return [
      CardAttribut('Simple', [
        AttributDesc('Text', Icons.format_quote, 'Text'),
        AttributDesc('Integer', Icons.pin, 'Integer'),
        AttributDesc('Double', Icons.percent, 'Double'),
        AttributDesc('Date', Icons.event, 'Date')
      ]),
      CardAttribut('Link', [
        AttributDesc('One', Icons.looks_one, 'One'),
        AttributDesc('Many', Icons.data_array_rounded, 'Many'),
      ])
    ];
  }

  AttributDesc(this.name, this.icon, String attr) {
    impl = attr;
  }

  String name;
  IconData icon;
  late String impl;
}

// ignore: must_be_immutable
class CardAttribut extends StatelessWidget {
  CardAttribut(this.category, this.nameComp, {super.key});
  String category;
  List<AttributDesc> nameComp;

  Offset dragAnchorStrategy(
      Draggable<Object> d, BuildContext context, Offset point) {
    return Offset(d.feedbackOffset.dx + 0, d.feedbackOffset.dy + 0);
  }

  @override
  Widget build(BuildContext context) {
    Widget buildComp(AttributDesc cmp) {
      return Padding(
          padding: const EdgeInsets.all(5.0),
          child: Draggable<String>(
            onDragStarted: () {
              // GlobalSnackBar.show(context, 'Drag started');
            },
            dragAnchorStrategy: dragAnchorStrategy,
            data: cmp.impl, // DragCtx(cmp, null),
            feedback: Container(
              color: Theme.of(context).primaryColor,
              height: 30.0,
              width: 50.0,
              child: Icon(cmp.icon),
            ),
            child: InkWell(
                onTap: () {},
                child: Row(children: [
                  Icon(cmp.icon),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(cmp.name))
                ])),
          ));
    }

    Widget buildList() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var cmp in nameComp) buildComp(cmp),
        ],
      );
    }

    var header = Container(
      color: Theme.of(context).secondaryHeaderColor,
      child: Row(
        children: [
          ExpandableIcon(
            theme: const ExpandableThemeData(
              animationDuration: Duration(milliseconds: 100),
              expandIcon: Icons.arrow_right,
              collapseIcon: Icons.arrow_drop_down,
              iconColor: Colors.white,
              iconSize: 28.0,
              iconRotationAngle: math.pi / 2,
              iconPadding: EdgeInsets.only(right: 5),
              hasIcon: false,
            ),
          ),
          Expanded(
            child: Text(
              category,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    final ctrl = ExpandableController(initialExpanded: true);
    //ctrl.value = false;

    return ExpandableNotifier(
      controller: ctrl,
      child: ScrollOnExpand(
        child: Column(
          children: <Widget>[
            ExpandablePanel(
              theme: const ExpandableThemeData(
                animationDuration: Duration(milliseconds: 100),
                headerAlignment: ExpandablePanelHeaderAlignment.center,
                // tapBodyToExpand: true,
                // tapBodyToCollapse: true,
                hasIcon: false,
              ),
              header: header,
              collapsed: Container(),
              expanded: buildList(),
            ),
          ],
        ),
      ),
    );
  }
}
