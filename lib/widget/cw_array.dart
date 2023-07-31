import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_slot.dart';
import '../designer/cw_factory.dart';
import '../designer/widget_crud.dart';
import 'cw_row.dart';

class CWArray extends CWWidgetMap {
  CWArray({super.key, required super.ctx});

  @override
  State<CWArray> createState() => _CwArrayState();

  @override
  initSlot(String path) {
    final nb = getCountChildren();
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

  final Map<int, State> listState = {};
}

class _CwArrayState extends StateCW<CWArray> {
  final ScrollController horizontal = ScrollController();
  final ScrollController vertical = ScrollController();

  @override
  void dispose() {
    super.dispose();
    horizontal.dispose();
    vertical.dispose();
  }

  final double minWidth = 100.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      final List<Widget> listHeader = [];

      final nb = widget.getCountChildren();
      final w = constraint.maxWidth.clamp(minWidth * nb + 24 + 9, 50000.0);
      final maxWidth = (w - 24 - 9) / nb;

      for (var i = 0; i < nb; i++) {
        listHeader.add(getHeader(i, maxWidth));
      }

      // header delete
      listHeader.add(const SizedBox(
        width: 24,
      ));

      var listView = ListView.builder(
          scrollDirection: Axis.vertical,
          controller: vertical,
          shrinkWrap: true,
          itemCount: widget.getItemsCount(),
          itemBuilder: (context, index) {
            List<Widget> listConts = getRow(nb, index, maxWidth);

            getARow() {
              return getRow(nb, index, maxWidth);
            }

            widget.setIdx(index);
            var rowState = CWArrayRow(
              key: ValueKey(index),
              rowIdx: index,
              stateArray: this,
              getRow: getARow,
              children: listConts,
            );

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
          });

      const int heightHeader = 28;
      return SizedBox(
          width: w,
          height: constraint.maxHeight,
          child: Scrollbar(
              thumbVisibility: true,
              trackVisibility: true,
              controller: horizontal,
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: horizontal,
                  child: SizedBox(
                      width: w,
                      child: Column(children: [
                        Container(
                            color: Colors.grey.shade800,
                            child: Row(children: listHeader)),
                        Scrollbar(
                            thumbVisibility: true,
                            trackVisibility: true,
                            controller: vertical,
                            child: SizedBox(
                                height: constraint.maxHeight - heightHeader,
                                child: listView)),
                        const SizedBox(height: 9) // zone scrollbar
                      ])))
              //)
              )
          //)
          );
    });
  }

  List<Widget> getRow(int nbCol, int idxRow, double maxWidth) {
    final List<Widget> listConts = [];
    CWProvider? provider = CWProvider.of(widget.ctx);
    for (var i = 0; i < nbCol; i++) {
      dynamic content = "";
      var createInArrayCtx = widget.createInArrayCtx('Cont$i', null);
      var w = createInArrayCtx.getWidgetInSlot();
      if (w is CWWidgetMap) {
        if (provider != null) {
          provider.idxDisplayed = idxRow;
          content = w.getValue();
        }
      }

      listConts.add(getCell(
          CWSlot(
              key: widget.ctx.getSlotKey('Cont$i$idxRow', content.toString()),
              ctx: createInArrayCtx),
          i,
          maxWidth));
    }

    // delete
    listConts.add(const WidgetDeleteBtn());
    return listConts;
  }

  Widget getHeader(int i, double maxWidth) {
    return getCell(
        CWSlot(
            key: widget.ctx.getSlotKey('Header$i', ''),
            ctx: widget.createInArrayCtx('Header$i', null)),
        i,
        maxWidth);
  }

  Widget getCell(Widget cell, int numCol, double max) {
    return SizedBox(
        width: max.clamp(minWidth, 500),
        child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                border:
                    Border(right: BorderSide(color: Colors.black, width: 1))),
            child: cell));
  }
}
