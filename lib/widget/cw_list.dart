import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_future.dart';
import '../core/widget/cw_core_slot.dart';
import '../designer/cw_factory.dart';
import 'cw_row.dart';

class CWList extends CWWidgetMap {
  CWList({super.key, required super.ctx})
  {
    print("create list ${ctx.xid} h=$hashCode");
  }

  @override
  State<CWList> createState() => _CwListState();

  @override
  initSlot(String path) {
    addSlotPath('$path[].Cont', SlotConfig('${ctx.xid}Cont'));
  }

  static initFactory(CWCollection c) {
    c
        .addWidget(
            (CWList), (CWWidgetCtx ctx) => CWList(key: ctx.getKey(), ctx: ctx))
        .addAttr('providerName', CDAttributType.CDtext);
  }
}

class InheritedStateContainer extends InheritedWidget {
  // Data is your entire state.
  final StateCW<CWWidgetMap> arrayState;
  final CwRowState? rowState;
  final int? index;

  // You must pass through a child and your state.
  const InheritedStateContainer(
      {Key? key,
      this.index,
      required this.arrayState,
      required Widget child,
      this.rowState})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }

  void selected(CWWidgetCtx ctx) {
    CWWidgetEvent ctxWE = CWWidgetEvent();
    ctxWE.action = CWProviderAction.onRowSelected.toString();
    CWProvider? provider = CWProvider.of(arrayState.widget.ctx);
    if (provider != null) {
      ctxWE.provider = provider;
      ctxWE.payload = index;
      ctxWE.loader = arrayState.widget.ctx.loader;
      if (provider.idxSelected != index) {
        provider.idxSelected = index!;
        provider.doAction(ctx, ctxWE, CWProviderAction.onRowSelected);
      }
    }
  }

  void repaintRow(CWWidgetCtx ctx) {
    if (rowState?.mounted ?? false) {
      //ignore: invalid_use_of_protected_member
      rowState?.setState(() {});
    }
  }
}

class _CwListState extends StateCW<CWList> {
  @override
  void initState() {
    super.initState();
    print("h ${widget.hashCode} xid=${widget.ctx.xid} state = ${widget.ctx.state}");
  }

  getListView(int nbRow) {
    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: nbRow,
        itemBuilder: (context, index) {
          widget.setIdx(index);
          var rowState = InheritedStateContainer(
              key: ValueKey(index),
              index: index,
              arrayState: this,
              child: CWSlot(
                  key: widget.ctx.getSlotKey('Cont$index', ''),
                  ctx: widget.createInArrayCtx('Cont', null)));
          return InkWell(
              onTap: () {
                rowState.selected(widget.ctx);
              },
              child: rowState);
        });
  }

  @override
  Widget build(BuildContext context) {
    var futureData = widget.initFutureDataOrNot(CWProvider.of(widget.ctx));

    getContent(int ok) {
      var provider = CWProvider.of(widget.ctx);
      widget.setProviderDataOK(provider, ok);
      return getListView(ok);
    }

    if (futureData is Future) {
      return CWFutureWidget(
        futureData: futureData,
        getContent: getContent,
        nbCol: 1,
      );
    } else {
      return getContent(futureData as int);
    }
  }
}
