import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_slot.dart';
import '../designer/cw_factory.dart';
import 'cw_row.dart';

class CWList extends CWWidgetMap {
  const CWList({super.key, required super.ctx});

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
    ctxWE.action = CWProviderAction.onSelected.toString();
    CWProvider? provider = CWProvider.of(arrayState.widget.ctx);
    if (provider != null) {
      ctxWE.provider = provider;
      ctxWE.payload = index;
      ctxWE.loader = arrayState.widget.ctx.loader;
      if (provider.idxSelected != index) {
        provider.idxSelected = index!;
        provider.doAction(ctx, ctxWE, CWProviderAction.onSelected);
      }
    }
  }

  void repaintRow(CWWidgetCtx ctx) {

    // if (rowState?.mounted ?? false) {
    //   //ignore: invalid_use_of_protected_member
    //   rowState?.setState(() {});
    // }


    // WidgetFactoryEventHandler f = arrayState.widget.ctx.factory;
    // int nbCol = arrayState.widget.getCountChildren();
    // for (var i = 0; i < nbCol; i++) {
    //   String p = "${arrayState.widget.ctx.pathWidget}[].Cont$i";
    //   String xid = f.mapXidByPath[p] ?? "?";
    //   CWWidget? w = ctx.findWidgetByXid(xid);
    //   w?.repaint();
    // }

    if (rowState?.mounted ?? false) {
      //ignore: invalid_use_of_protected_member
      rowState?.setState(() {});
    }
  }
}

class _CwListState extends StateCW<CWList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: widget.getItemsCount(),
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
}
