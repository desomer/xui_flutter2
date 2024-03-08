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
    var columnOn = <Widget>[
      const Text('On'),
      ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 35),
          child: RadioListTile<String>(
            contentPadding: const EdgeInsets.all(0),
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
        constraints: const BoxConstraints(maxHeight: 35),
        child: RadioListTile<String>(
          contentPadding: const EdgeInsets.all(0),
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
      children: columnOn,
    );
    var column2 = const Column(
      children: [Text('Do')],
    );
    var column3 = const Column(
      children: [Text('If')],
    );

    return SizedBox(
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
