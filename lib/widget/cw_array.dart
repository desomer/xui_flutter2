import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_slot.dart';
import '../designer/cw_factory.dart';
import 'cw_list.dart';

class CWArray extends CWWidgetMap {
  const CWArray({super.key, required super.ctx});

  @override
  State<CWArray> createState() => _CwArrayState();

  @override
  initSlot(String path) {
    final nb = getCount();
    for (var i = 0; i < nb; i++) {
      addSlotPath(
          '$path[].Header$i',
          SlotConfig('${ctx.xid}Header$i',
              constraintEntity: "CWColArrayConstraint"));
      addSlotPath('$path[].Cont$i', SlotConfig('${ctx.xid}Cont$i'));
    }
  }

  static initFactory(CWCollection c) {
    c
        .addWidget((CWArray),
            (CWWidgetCtx ctx) => CWArray(key: ctx.getKey(), ctx: ctx))
        .addAttr('count', CDAttributType.CDint)
        .addAttr('providerName', CDAttributType.CDtext);

    c.collection
        .addObject('CWColArrayConstraint')
        .addAttr('width', CDAttributType.CDint);
  }
}

class _CwArrayState extends StateCW<CWArray> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> listHeader = [];

    final nb = widget.getCount();
    for (var i = 0; i < nb; i++) {
      listHeader.add(getHeader(i));
    }

    listHeader.add(const SizedBox(
      width: 24,
    ));

    return Column(children: [
      Container(color: Colors.grey.shade800, child: Row(children: listHeader)),
      ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: widget.getItemsCount(),
          itemBuilder: (context, index) {
            final List<Widget> listConts = [];
            for (var i = 0; i < nb; i++) {
              listConts.add(getCell(
                  CWSlot(
                      key: widget.ctx.getSlotKey('Cont$i$index'),
                      ctx: widget.createInArrayCtx('Cont$i', null)),
                  i));
            }

            listConts.add(InkWell(
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.delete_forever, size: 20),
              ),
              onTap: () {},
            ));

            widget.setIdx(index);
            var rowState = InheritedStateContainer(
                key: ValueKey(index),
                index: index,
                data: this,
                child: Row(
                  children: listConts,
                ));

            return GestureDetector(
                // la row
                onTap: () {
                  rowState.selected(widget.ctx);
                },
                child: Container(
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(width: 1.0, color: Colors.grey))),
                    child: rowState));
          })
    ]);
  }

  Widget getHeader(int i) {
    return getCell(
        CWSlot(
            key: widget.ctx.getSlotKey('Header$i'),
            ctx: widget.createInArrayCtx('Header$i', null)),
        i);
  }

  Widget getCell(Widget cell, int numCol) {
    if (numCol == 0) {
      return SizedBox(
          width: 200,
          child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  border:
                      Border(right: BorderSide(color: Colors.black, width: 1))),
              child: cell));
    } else {
      return Flexible(
          flex: 1,
          fit: FlexFit.tight,
          child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  border:
                      Border(right: BorderSide(color: Colors.black, width: 1))),
              child: cell));
    }
  }
}
