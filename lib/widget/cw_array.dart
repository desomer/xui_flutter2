import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_future.dart';
import '../core/widget/cw_core_slot.dart';
import '../designer/cw_factory.dart';
import '../designer/widget_crud.dart';
import 'cw_row.dart';

class CWArray extends CWWidgetMap {
  const CWArray({super.key, required super.ctx});

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
    var futureData = widget.initFutureDataOrNot(CWProvider.of(widget.ctx));

    return LayoutBuilder(builder: (context, constraint) {
      final nbCol = widget.getCountChildren();
      final w = constraint.maxWidth.clamp(minWidth * nbCol + 24 + 9, 50000.0);
      final widthCol = (w - 24 - 9) / nbCol;

      List<Widget> listHeader = getListWidgetHeader(nbCol, widthCol);

      getContent(int ok) {
        var provider = CWProvider.of(widget.ctx);
        widget.setProviderDataOK(provider, ok);
        return getArray(w, constraint.maxHeight, Row(children: listHeader),
            getListView(nbCol, widthCol, ok));
      }

      if (futureData is Future) {
        return CWFutureWidget(futureData: futureData, getContent: getContent, nbCol: nbCol );
      } else {
        return getContent(futureData as int);
      }
    });
  }

  List<Widget> getListWidgetHeader(int nbCol, double maxWidth) {
    final List<Widget> listHeader = [];
    for (var i = 0; i < nbCol; i++) {
      listHeader.add(getHeader(i, maxWidth));
    }
    // header delete
    listHeader.add(const SizedBox(
      width: 24,
    ));
    return listHeader;
  }

  Widget getArray(double w, double h, Row header, ListView content) {
    const int heightHeader = 28;
    return SizedBox(
        width: w,
        height: h,
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
                      Container(color: Colors.grey.shade800, child: header),
                      Scrollbar(
                          thumbVisibility: true,
                          trackVisibility: true,
                          controller: vertical,
                          child: SizedBox(
                              height: h - heightHeader, child: content)),
                      const SizedBox(height: 9) // zone scrollbar
                    ])))
            //)
            )
        //)
        );
  }

  ListView getListView(int nbCol, double maxWidth, nbRow) {
    var listView = ListView.builder(
        scrollDirection: Axis.vertical,
        controller: vertical,
        shrinkWrap: true,
        itemCount: nbRow,
        itemBuilder: (context, index) {
          List<Widget> listConts = getRow(nbCol, index, maxWidth);

          getARow() {
            return getRow(nbCol, index, maxWidth);
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
                          bottom: BorderSide(width: 1.0, color: Colors.grey))),
                  child: rowState));
        });
    return listView;
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
