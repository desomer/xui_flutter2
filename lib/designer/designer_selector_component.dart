import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../core/widget/cw_core_drag.dart';

class ComponentDesc {
  static List<Widget> get getListComponent {
    return [
      CardComponents('Layout', [
        ComponentDesc('Label', Icons.format_quote, 'CWText'),
        ComponentDesc('Column', Icons.table_rows_rounded, 'CWColumn'),
        ComponentDesc('Row', Icons.view_week, 'CWRow'),
        ComponentDesc('Tab', Icons.tab, 'CWTab'),
        ComponentDesc('Card', Icons.border_style, 'CWCard')
      ]),
      CardComponents('Array, Form & List', [
        ComponentDesc('Array', Icons.table_chart, 'CWArray'),
        ComponentDesc('Form', Icons.feed, 'CWForm'),
        ComponentDesc('List', Icons.view_list, 'CWList'),
      ]),
      CardComponents('Actions', [
        ComponentDesc('Button', Icons.smart_button_sharp, 'CWActionLink'),
      ]),
      // "Column", "Row", "Tab"
      // CardComponents("Filter", const [
      //   "Form",
      //   "Selector",
      // ]),
      // CardComponents(
      //     "Data", const ["Form", "List", "Tree" "List/Form", "Tree/Form"]),
      // CardComponents("Aggregat", const ["Sum", "Moy", "Count", "Chart"]),
      CardComponents('Input', [
        ComponentDesc('Text', Icons.text_fields, 'CWTextfield'),
        ComponentDesc('Switch', Icons.toggle_on, 'CWSwitch'),
        ComponentDesc('Dropdown', Icons.checklist_rounded, 'CWDropdown'),
        
      ]),
    ];
  }

  ComponentDesc(this.name, this.icon, this.impl);

  String name;
  IconData icon;
  String impl;
}

// ignore: must_be_immutable
class CardComponents extends StatelessWidget {
  CardComponents(this.category, this.nameComp, {super.key});
  String category;
  List<ComponentDesc> nameComp;

  Offset dragAnchorStrategy(
      Draggable<Object> d, BuildContext context, Offset point) {
    return Offset(d.feedbackOffset.dx + 0, d.feedbackOffset.dy + 0);
  }

  @override
  Widget build(BuildContext context) {
    Widget buildComp(ComponentDesc cmp) {
      return Padding(
          padding: const EdgeInsets.all(5.0),
          child: Draggable<DragComponentCtx>(
            onDragStarted: () {
              // GlobalSnackBar.show(context, 'Drag started');
            },
            dragAnchorStrategy: dragAnchorStrategy,
            data: DragComponentCtx(cmp, null),
            feedback: Container(
              color: Theme.of(context).primaryColor,
              height: 30.0,
              width: 50.0,
              child: Icon(cmp.icon),
            ),
            child: Row(children: [
              Icon(cmp.icon),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(cmp.name))
            ]),
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
      color: Theme.of(context).highlightColor,
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

// class GlobalSnackBar {
//   final String message;

//   const GlobalSnackBar({
//     required this.message,
//   });

//   static void show(
//     BuildContext context,
//     String message,
//   ) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         elevation: 1.0,
//         behavior: SnackBarBehavior.fixed,
//         content: Text(message),
//         duration: const Duration(seconds: 1),
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0)),
//         ),
//         //backgroundColor: Colors.redAccent,
//         action: SnackBarAction(
//           textColor: Colors.blue,
//           label: 'OK',
//           onPressed: () {},
//         ),
//       ),
//     );
//   }
// }
