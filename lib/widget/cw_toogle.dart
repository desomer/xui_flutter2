import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_data.dart';

import '../core/widget/cw_core_widget.dart';
import '../core/widget/cw_factory.dart';

class CWToogle extends CWWidgetMapLabel {
  const CWToogle({super.key, required super.ctx});

  @override
  State<CWToogle> createState() => _CWToogleState();

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget('CWToogle',
            (CWWidgetCtx ctx) => CWToogle(key: ctx.getKey(), ctx: ctx))
        .addAttr('label', CDAttributType.text)
        .addCustomValue('bindEnable', true)
        .addAttr('bind', CDAttributType.one, tname: 'info')
        .addAttr('bindValue', CDAttributType.many, tname: '#bindValue');
  }

  List? getBindValue() {
    return ctx.designEntity?.getMany('bindValue');
  }

  @override
  void initSlot(String path, ModeParseSlot mode) {}
}

class _CWToogleState extends StateCW<CWToogle> {
  late List<bool> isSelected;
  List<IconData> listIcons = [];
  List<String> listValue = [];

  @override
  void initState() {
    // this is for 3 buttons, add "false" same as the number of buttons here
    List l = widget.getBindValue()!;

    isSelected = [];
    // ignore: unused_local_variable
    for (var element in l) {
      isSelected.add(false);
      listIcons.add(element['icon'] as IconData);
      listValue.add(element['value'].toString());
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = 30;

    var bind = widget.ctx.designEntity?.getOne('@bind');
    var mapValue = widget.getMapString(provInfo: bind);
    for (int i = 0; i < isSelected.length; i++) {
      if (listValue[i] == mapValue) {
        isSelected[i] = true;
      }
    }

    return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
              child: Text(widget.getLabel(''))),
          const Spacer(),
          ToggleButtons(
              isSelected: isSelected,
              constraints: BoxConstraints(
                  maxWidth: width,
                  minWidth: width,
                  minHeight: width,
                  maxHeight: width),
              children: listIcons.map((e) => Icon(e)).toList(),
              onPressed: (int newIndex) {
                setState(() {
                  for (int i = 0; i < isSelected.length; i++) {
                    isSelected[i] = i == newIndex ? (!isSelected[i]) : false;
                    if (i == newIndex) {
                      var bind = widget.ctx.designEntity?.getOne('@bind');
                      widget.setValue(isSelected[i] ? listValue[i] : null,
                          provInfo: bind);
                    }
                  }
                });
              })
        ]);

    // return const Row(
    //   mainAxisSize: MainAxisSize.max,
    //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //   children: [Icon(Icons.abc), Icon(Icons.ac_unit)],
    // );
  }
}
