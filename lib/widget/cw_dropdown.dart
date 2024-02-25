import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_factory.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class CWDropdown extends CWWidgetMapValue {
  const CWDropdown({super.key, required super.ctx});

  @override
  State<CWDropdown> createState() => _CWDropdownState();

  @override
  void initSlot(String path, ModeParseSlot mode) {}

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget('CWDropdown',
            (CWWidgetCtx ctx) => CWDropdown(key: ctx.getKey(), ctx: ctx))
        .addAttr('label', CDAttributType.text)
        .addCustomValue('bindEnable', true)
        .addAttr('bind', CDAttributType.one, tname: 'info');
  }
}

class _CWDropdownState extends State<CWDropdown> {
  final List<String> _list = [
    'Developer',
    'Designer',
    'Consultant',
    'Student',
  ];

  @override
  Widget build(BuildContext context) {
    return  CustomDropdown<String>(
      decoration: CustomDropdownDecoration(headerStyle: Theme.of(context).textTheme.bodyLarge ),
      
      closedHeaderPadding: const EdgeInsets.all(8),
      expandedHeaderPadding: const EdgeInsets.all(8),
      itemsListPadding:  const EdgeInsets.all(0),
      listItemPadding:  const EdgeInsets.all(8),
      hintText: 'Select job role',
      items: _list,
      //initialItem: _list[0],
      onChanged: (value) {
      },
    );
  }
}
