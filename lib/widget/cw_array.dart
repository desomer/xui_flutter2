import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_future.dart';
import '../core/widget/cw_core_slot.dart';
import '../designer/builder/array_builder.dart';
import '../designer/cw_factory.dart';
import '../designer/designer_query.dart';
import '../designer/widget_crud.dart';
import 'cw_array_row.dart';

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
      addSlotPath('$path[].RowCont$i', SlotConfig('${ctx.xid}RowCont$i'));
    }
  }

  static initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget("CWArray",
            (CWWidgetCtx ctx) => CWArray(key: ctx.getKey(), ctx: ctx))
        .addAttr('count', CDAttributType.int)
        .addAttr('providerName', CDAttributType.text);

    c.collection
        .addObject('CWColArrayConstraint')
        .addAttr('width', CDAttributType.int);
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
  final double heightHeader = 40;
  final double heightScroll = 12;

  @override
  Widget build(BuildContext context) {
    var provider = CWProvider.of(widget.ctx);
    var futureData = widget.initFutureDataOrNot(provider, widget.ctx);

    return LayoutBuilder(builder: (context, constraint) {
      final nbCol = widget.getCountChildren();
      final w = constraint.maxWidth.clamp(minWidth * nbCol + 24 + 9, 50000.0);
      final widthCol = (w - 24 - 9) / nbCol;

      List<Widget> listHeader =
          getListWidgetHeader(nbCol, widthCol, heightHeader);

      getContent(int ok) {
        widget.setProviderDataOK(provider, ok);

        if (widget.ctx.loader.mode == ModeRendering.design) ok = 1;

        return getArray(w, constraint.maxHeight, nbCol,
            Row(children: listHeader), getListView(nbCol, widthCol, ok));
      }

      if (futureData is Future) {
        return CWFutureWidget(
            futureData: futureData, getContent: getContent, nbCol: nbCol);
      } else {
        return getContent(futureData as int);
      }
    });
  }

  List<Widget> getListWidgetHeader(int nbCol, double maxWidth, double height) {
    final List<Widget> listHeader = [];
    for (var i = 0; i < nbCol; i++) {
      listHeader.add(getHeader(i, maxWidth, height));
    }
    // header delete
    listHeader.add(const SizedBox(
      width: 24,
    ));
    return listHeader;
  }

  Widget getDropZone(Widget child) {
    return DragTarget<DragQueryCtx>(
        builder: (context, candidateItems, rejectedItems) {
      return AnimatedScale(
          scale: candidateItems.isEmpty ? 1 : 0.95,
          duration: const Duration(milliseconds: 100),
          child: child);
    }, onWillAccept: (item) {
      return true;
    }, onAccept: (item) async {
      ArrayBuilder().createArray(widget, item.query);
    });
  }

  static const double heightBorder = 1;
  static const double borderDrag = 10;

  Widget getArray(double w, double h, int nbCol, Row header, ListView content) {
    Widget sizedContent = content;
    if (nbCol == 0) {
      sizedContent = ListView(
          scrollDirection: Axis.vertical,
          controller: vertical,
          shrinkWrap: true,
          children: [getDropQuery(h)]);
    } else if (h != double.infinity) {
      sizedContent = SizedBox(
          height: h - heightHeader - heightScroll - heightBorder * 2,
          child: content);
    }

    return Container(
        decoration: BoxDecoration(
            border: Border.all(
                width: heightBorder, color: Theme.of(context).dividerColor)),
        width: w,
        height: h != double.infinity ? h : null,
        child: MediaQuery(
            data: MediaQuery.of(context).removePadding(removeBottom: true),
            child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                controller: horizontal,
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: horizontal,
                    child: SizedBox(
                        width: w - heightBorder * 2, // 2 = border
                        child: Column(children: [
                          Container(
                              color: Theme.of(context).secondaryHeaderColor,
                              child: header),
                          Scrollbar(
                              thumbVisibility: true,
                              trackVisibility: true,
                              controller: vertical,
                              child: sizedContent),
                          SizedBox(height: heightScroll) // zone scrollbar
                        ])))
                //)
                ))
        //)
        );
  }

  Widget getDropQuery(double h) {
    return getDropZone(Container(
        margin:
            const EdgeInsets.fromLTRB(borderDrag, borderDrag, borderDrag, 0),
        height: h != double.infinity
            ? h - heightScroll - (heightBorder * 2) - borderDrag
            : 100,
        child: DottedBorder(
            color: Colors.grey,
            dashPattern: const <double>[6, 4],
            strokeWidth: 2,
            child: const Center(
                child: IntrinsicWidth(
                    child: Row(children: [
              Text("Drag query here"),
              Icon(Icons.filter_alt)
            ]))))));
  }

  ListView getListView(int nbCol, double maxWidth, nbRow) {
    if (nbRow < 0) nbRow = 0;

    var listView = ListView.builder(
        scrollDirection: Axis.vertical,
        controller: vertical,
        shrinkWrap: true,
        itemCount: nbRow,
        itemBuilder: (context, index) {
          getARowBuilder(CWArrayRowState rowState) {
            return getRowBuilder(rowState, nbCol, index, maxWidth);
          }

          widget.setIdx(index);
          var aCWRow = CWArrayRow(
            key: ValueKey(index),
            rowIdx: index,
            stateArray: this,
            getRowBuilder: getARowBuilder,
          );

          return GestureDetector(
              // la row
              onTap: () {
                aCWRow.selected(widget.ctx);
              },
              child: Container(
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(width: 1.0, color: Colors.grey))),
                  child: aCWRow));
        });
    return listView;
  }

  CWProvider? provider;
  List<Widget> getRowBuilder(
      CWArrayRowState rowState, int nbCol, int idxRow, double maxWidth) {
    final List<Widget> listConts = [];
    provider = CWProvider.of(widget.ctx);
    for (var i = 0; i < nbCol; i++) {
      dynamic content = "";
      // recupére le slot du design
      var createInArrayCtx = widget.createInArrayCtx('RowCont$i', null);
      var w = createInArrayCtx.getWidgetInSlot();
      if (w is CWWidgetMap) {
        if (provider != null) {
          provider!.getData().idxDisplayed = idxRow;
          content = w.getMapValue();
        }
      }
      // duplique les slot par ligne de tableau
      listConts.add(getCell(
          CWSlot(
              type: "datacell",
              key: widget.ctx.getSlotKey(
                  idxRow == 0 ? 'RowCont{$i}' : 'RowCont{$i}_$idxRow',
                  content.toString()),
              ctx: createInArrayCtx),
          i,
          maxWidth,
          null));
    }

    // delete
    listConts.add(const WidgetDeleteBtn());
    return listConts;
  }

  Offset dragAnchorStrategy(
      Draggable<Object> d, BuildContext context, Offset point) {
    return Offset(d.feedbackOffset.dx + 25, d.feedbackOffset.dy - 5);
  }

  Widget getDrag(int i, Widget child) {
    return Draggable<DragColCtx>(
        dragAnchorStrategy: dragAnchorStrategy,
        onDragStarted: () {
          // GlobalSnackBar.show(context, 'Drag started');
        },
        data: DragColCtx(provider, i),
        feedback: Container(
            height: 30,
            width: 100,
            color: Colors.grey,
            child: const Center(child: Icon(Icons.abc))),
        child: child);
  }

  Widget getHeader(int i, double maxWidth, double h) {
    return getDrag(
        i,
        getCell(
            CWSlot(
                type: "dataHeader",
                key: widget.ctx.getSlotKey('Header$i', ''),
                ctx: widget.createInArrayCtx('Header$i', null)),
            i,
            maxWidth,
            h));
  }

  Widget getCell(Widget cell, int numCol, double max, double? height) {
    return SizedBox(
        width: max.clamp(minWidth, 500),
        height: height,
        child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(
                        color: Theme.of(context).dividerColor, width: 1))),
            child: cell));
  }
}

class DragColCtx {
  DragColCtx(this.provider, this.idxCol);
  CWProvider? provider;
  int idxCol;
}
