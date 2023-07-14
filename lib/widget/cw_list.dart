import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_slot.dart';
import '../designer/cw_factory.dart';

class CWList extends CWWidgetMap {
  const CWList({super.key, required super.ctx});

  @override
  State<CWList> createState() => _CwListState();

  @override
  initSlot(String path) {
    addSlotPath('$path.Cont', SlotConfig('${ctx.xid}Cont'));
  }

  static initFactory(CWCollection c) {
    c
        .addWidget(
            (CWList), (CWWidgetCtx ctx) => CWList(key: ctx.getKey(), ctx: ctx))
        .addAttr('providerName', CDAttributType.CDtext);
  }
}

class _CwListState extends State<CWList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: widget.getItemsCount(),
        itemBuilder: (context, index) {
          widget.setIdx(index);
          return InkWell(
              //splashColor: Colors.yellow,
              onTap: () {
                print('$index');
              },
              child: CWSlot(
                  key: widget.ctx.getSlotKey('Cont'),
                  ctx: widget.createChildCtx('Cont', null)));
        });
  }
}
