import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_link.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/designer.dart';
import 'package:xui_flutter/widget/cw_selector.dart';

import '../core/data/core_data.dart';
import '../core/data/core_repository.dart';
import '../core/widget/cw_core_drag.dart';
import '../core/widget/cw_core_future.dart';
import '../core/widget/cw_core_slot.dart';
import '../designer/builder/array_builder.dart';
import '../core/widget/cw_factory.dart';
import '../designer/widget_crud.dart';
import 'cw_array_row.dart';

class CWArray extends CWWidgetMapRepository {
  const CWArray({super.key, required super.ctx});

  @override
  State<CWArray> createState() => _CwArrayState();

  @override
  void initSlot(String path, ModeParseSlot mode) {
    final nb = getCountChildren();
    for (var i = 0; i < nb; i++) {
      addSlotPath(
          '$path[].Header$i',
          SlotConfig('${ctx.xid}Header$i',
              constraintEntity: 'CWColArrayConstraint'), mode);
      addSlotPath('$path[].RowCont$i', SlotConfig('${ctx.xid}RowCont$i'), mode);
    }
  }

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget('CWArray',
            (CWWidgetCtx ctx) => CWArray(key: ctx.getKey(), ctx: ctx))
        .addAttr(iDCount, CDAttributType.int)
        .addAttr(iDProviderName, CDAttributType.text,
            tname: CWSelectorType.provider.name)
        .addAttr('behaviour', CDAttributType.one,
            tname: CWSelectorType.behaviour.name);

    c.collection
        .addObject('CWColArrayConstraint')
        .addAttr('width', CDAttributType.int);
  }
}

class _CwArrayState extends StateCW<CWArray> {
  final ScrollController horizontal = ScrollController();
  final ScrollController vertical = ScrollController();
  //final GlobalKey listKey = GlobalKey();
  final CWSynchonizedManager synchonizedManager = CWSynchonizedManager();

  @override
  void initState() {
    super.initState();
    synchonizedManager.initAction(widget, widget.getRepository());
  }

  @override
  void dispose() {
    super.dispose();
    horizontal.dispose();
    vertical.dispose();
    // widget
    //     .getRepository()
    //     ?.removeAction(CWRepositoryAction.onValidateEntity, actionRepaint);
    // widget
    //     .getRepository()
    //     ?.removeAction(CWRepositoryAction.onRefreshEntities, actionRefresh);
  }

  final double minWidth = 100.0;
  final double heightHeader = 40;
  final double heightScroll = 12;

  //Map cache = {};

  @override
  Widget build(BuildContext context) {
    var provider = CWRepository.of(widget.ctx);
    //debugPrint('display provider ${provider!.name} hash = ${provider.getData().hashCode}');
    var futureData = widget.initFutureDataOrNot(provider, widget.ctx);

    return LayoutBuilder(builder: (context, constraint) {
      final nbCol = widget.getCountChildren();
      final w = constraint.maxWidth.clamp(minWidth * nbCol + 24 + 9, 50000.0);
      final widthCol = (w - 24 - 9) / nbCol;

      List<Widget> listHeader =
          _getListWidgetHeader(nbCol, widthCol, heightHeader);

      Widget getContent(int ok) {
        widget.setProviderDataOK(provider, ok);

        if (widget.ctx.loader.mode == ModeRendering.design) ok = 1;

        return getArray(w, constraint.maxHeight, nbCol,
            Row(children: listHeader), _getListView(nbCol, widthCol, ok));
      }

      if (futureData is Future) {
        return CWFutureWidget(
            futureData: futureData, getContent: getContent, nbCol: nbCol);
      } else {
        return getContent(futureData as int);
      }
    });
  }

  List<Widget> _getListWidgetHeader(int nbCol, double maxWidth, double height) {
    final List<Widget> listHeader = [];
    for (var i = 0; i < nbCol; i++) {
      listHeader.add(_getHeader(i, maxWidth, height));
    }
    // header delete
    listHeader.add(const SizedBox(
      width: 24,
    ));
    return listHeader;
  }

  Widget _getDroppable(Widget child) {
    return DragTarget<DragQueryCtx>(
        builder: (context, candidateItems, rejectedItems) {
      return AnimatedScale(
          scale: candidateItems.isEmpty ? 1 : 0.95,
          duration: const Duration(milliseconds: 100),
          child: child);
    }, onWillAcceptWithDetails: (item) {
      return true;
    }, onAcceptWithDetails: (item) async {
      await ArrayBuilder(loaderCtx: widget.ctx.loader)
          .initDesignArrayFromQuery(widget, item.data.query, 'Array');
      CoreDesigner.of().providerKey.currentState!.setState(() {});
    });
  }

  static const double heightBorder = 1;
  static const double borderDrag = 10;

  Widget getArray(double w, double h, int nbCol, Row header, Widget content) {
    Widget sizedContent = content;

    styledBox.init();
    styledBox.setConfigBox();
    styledBox.setConfigMargin();

    var hC = (styledBox.config.decoration != null
            ? styledBox.config.hBorder
            : (heightBorder * 2)) +
        styledBox.config.hMargin +
        styledBox.config.hPadding;

    if (nbCol == 0) {
      sizedContent = ListView(
          scrollDirection: Axis.vertical,
          controller: vertical,
          shrinkWrap: true,
          children: [getDropQuery(h)]);
    } else if (h != double.infinity) {
      sizedContent = SizedBox(
          height: h - heightHeader - heightScroll - hC, child: content);
    }

    styledBox.config.decoration = styledBox.config.decoration ??
        BoxDecoration(
            border: Border.all(
                width: heightBorder, color: Theme.of(context).dividerColor));

    styledBox.config.width = w;
    styledBox.config.height = h != double.infinity ? h : null;

    return styledBox.getStyledContainer(MediaQuery(
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
                              color: Theme.of(context).highlightColor,
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
    return _getDroppable(Container(
        margin:
            const EdgeInsets.fromLTRB(borderDrag, borderDrag, borderDrag, 0),
        height: h != double.infinity
            ? h - heightScroll - (heightBorder * 2) - borderDrag
            : 100,
        child: DottedBorder(
            color: Theme.of(context).dividerColor,
            dashPattern: const <double>[6, 4],
            strokeWidth: 2,
            child: const Center(
                child: IntrinsicWidth(
                    child: Row(children: [
              Text('Drag query or result here'),
              Icon(Icons.filter_alt)
            ]))))));
  }

  Widget _getListView(int nbCol, double maxWidth, nbRow) {
    if (nbRow < 0) nbRow = 0;

    var listView = ListView.builder(
        //key: listKey,
        scrollDirection: Axis.vertical,
        controller: vertical,
        shrinkWrap: true,
        itemCount: nbRow,
        itemBuilder: (context, index) {
          List<Widget> getARowBuilder(CWArrayRowState rowState) {
            return _getRowBuilder(rowState, nbCol, index, maxWidth);
          }

          // CwRow? row = cache['$index'];
          // if (row == null) {
          widget.setDisplayedIdx(index);
          var aCWRow = CWArrayRow(
            key: ValueKey(index),
            rowIdx: index,
            stateArray: this,
            getRowBuilder: getARowBuilder,
          );

          var row = CwRow(key: ValueKey(index), aCWRow: aCWRow);
          //   cache['$index'] = row;
          // }

          return row;
        });
    return listView;
  }

  CWRepository? provider;
  List<Widget> _getRowBuilder(
      CWArrayRowState rowState, int nbCol, int idxRow, double maxWidth) {
    final List<Widget> listConts = [];
    provider = CWRepository.of(widget.ctx);
    provider?.displayRenderingMode = DisplayRenderingMode.displayed;
    provider?.getData().idxDisplayed = idxRow;

    for (var i = 0; i < nbCol; i++) {
      dynamic contentForKey = '';
      // recupére le slot du design
      var createInArrayCtx =
          widget.createInArrayCtx(widget.ctx, 'RowCont$i', null);
      var w = createInArrayCtx.getWidgetInSlot();

      if (w is CWWidgetMapValue) {
        if (provider != null) {
          var bind = w.ctx.designEntity
              ?.getOne(w is CWWidgetMapLabel ? '@label' : '@bind');
          contentForKey = w.getMapString(provInfo: bind);
        }
      }
      // duplique les slot par ligne de tableau pour une Key par cellule
      listConts.add(_getCell(
          CWSlot(
            type: 'datacell',
            key: widget.ctx.getSlotKey(
                idxRow == 0 ? 'RowCont{$i}' : 'RowCont{$i}_$idxRow',
                contentForKey.toString()),
            ctx: createInArrayCtx,
            slotAction: ColumnAction(),
          ),
          i,
          maxWidth,
          CWArrayRow.getHeightRow(widget)));
    }

    // delete
    listConts.add(const WidgetDeleteBtn());
    return listConts;
  }

  Offset dragAnchorStrategy(
      Draggable<Object> d, BuildContext context, Offset point) {
    return Offset(d.feedbackOffset.dx + 25, d.feedbackOffset.dy - 5);
  }

  Widget _getDraggable(int i, Widget child) {
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

  Widget _getHeader(int i, double maxWidth, double h) {
    return _getDraggable(
        i,
        _getCell(
            CWSlot(
              type: 'dataHeader',
              key: widget.ctx.getSlotKey('Header$i', ''),
              ctx: widget.createInArrayCtx(widget.ctx, 'Header$i', null),
              slotAction: ColumnAction(),
            ),
            i,
            maxWidth,
            h));
  }

  Widget _getCell(Widget cell, int numCol, double max, double? height) {
    return SizedBox(
        width: max.clamp(minWidth, 500),
        height: height,
        child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(
                        color: Theme.of(context).dividerColor, width: 0.5))),
            child: cell));
  }
}

class DragColCtx {
  DragColCtx(this.provider, this.idxCol);
  CWRepository? provider;
  int idxCol;
}

class ColumnAction extends SlotAction {
  @override
  bool canDelete() {
    return true;
  }

  @override
  bool doDelete(CWWidgetCtx ctx) {
    return true;
  }

  @override
  bool addBottom(CWWidgetCtx ctx) {
    throw UnimplementedError();
  }

  @override
  bool canAddBottom() {
    return false;
  }

  @override
  bool addTop(CWWidgetCtx ctx) {
    return true;
  }

  @override
  bool canAddTop() {
    return false;
  }

  @override
  bool canMoveBottom() {
    return false;
  }

  @override
  bool moveBottom(CWWidgetCtx ctx) {
    return true;
  }

  @override
  bool canMoveTop() {
    return false;
  }

  @override
  bool moveTop(CWWidgetCtx ctx) {
    return true;
  }

  @override
  bool addLeft(CWWidgetCtx ctx) {
    throw UnimplementedError();
  }

  @override
  bool addRight(CWWidgetCtx ctx) {
    throw UnimplementedError();
  }

  @override
  bool canAddLeft() {
    return false;
  }

  @override
  bool canAddRight() {
    return false;
  }

  @override
  bool canMoveLeft() {
    return false;
  }

  @override
  bool canMoveRight() {
    return false;
  }

  @override
  bool moveLeft(CWWidgetCtx ctx) {
    throw UnimplementedError();
  }

  @override
  bool moveRight(CWWidgetCtx ctx) {
    throw UnimplementedError();
  }
}

class CwRow extends StatelessWidget {
  const CwRow({super.key, required this.aCWRow});

  final CWArrayRow aCWRow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        // la row
        onTap: () {
          aCWRow.selected(aCWRow.stateArray.widget.ctx);
        },
        child: Container(
            decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(width: 1.0, color: Colors.grey))),
            child: aCWRow));
  }
}
