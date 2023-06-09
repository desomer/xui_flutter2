import 'package:flutter/material.dart';

import '../core/widget/cw_core_widget.dart';

class CWSwitch extends CWWidgetMap {
  const CWSwitch({
    super.key,
    required super.ctx,
  });

  @override
  State<CWSwitch> createState() => _CWSwitchState();

  @override
  initSlot(String path) {}
}

class _CWSwitchState extends StateCW<CWSwitch> {
  bool val = true;

  @override
  void initState() {
    super.initState();
    val = widget.getBool();
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
        contentPadding: const EdgeInsets.fromLTRB(5, 1, 5, 0),
        dense: true,
        title: Text(widget.getLabel()),
        // This bool value toggles the switch.
        value: val,
        // activeColor: Colors.red,
        onChanged: (bool value) {
          // This is called when the user toggles the switch.
          setState(() {
            if (value != val) widget.setValue(value);
            val = value;
          });
        });
  }
}
