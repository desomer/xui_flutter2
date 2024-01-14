import 'package:flutter/material.dart';

class DesignerSelectorBehaviour extends StatefulWidget {
  const DesignerSelectorBehaviour({super.key});

  @override
  State<DesignerSelectorBehaviour> createState() =>
      _DesignerSelectorBehaviourState();
}

class _DesignerSelectorBehaviourState extends State<DesignerSelectorBehaviour> {
  String? onEvent;

  @override
  Widget build(BuildContext context) {
    var ColumnOn = <Widget>[
      const Text("On"),
      ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 35),
          child: RadioListTile<String>(
            contentPadding: EdgeInsets.all(0),
            dense: true,
            title: const Text('Tap'),
            value: 'tap',
            groupValue: onEvent,
            onChanged: (String? value) {
              setState(() {
                onEvent = value;
              });
            },
          )),
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 35),
        child: RadioListTile<String>(
          contentPadding: EdgeInsets.all(0),
          dense: true,
          title: const Text('Double Tap'),
          value: 'dbtap',
          groupValue: onEvent,
          onChanged: (String? value) {
            setState(() {
              onEvent = value;
            });
          },
        ),
      )
    ];

    var column1 = Column(
      children: ColumnOn,
    );
    var column2 = Column(
      children: [Text("Do")],
    );
    var column3 = Column(
      children: [Text("If")],
    );

    return Container(
      width: 700,
      height: 300,
      child: Row(mainAxisSize: MainAxisSize.max, children: [
        getColumn(column1),
        getColumn(column2),
        getColumn(column3)
      ]),
    );
  }

  Flexible getColumn(Column column) => Flexible(
      flex: 1,
      fit: FlexFit.tight,
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor)),
        child: column,
      ));
}
