import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_slot.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/cw_factory.dart';

class CWTab extends CWWidget {
  const CWTab({
    super.key,
    required super.ctx,
  });

  static initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget(
            "CWTab", (CWWidgetCtx ctx) => CWTab(key: ctx.getKey(), ctx: ctx))
        .addAttr('tabCount', CDAttributType.int)
        .withAction(AttrActionDefault(2))
        .addAttr('heightTabBar', CDAttributType.int)
        .addAttr('height', CDAttributType.int);
  }

  @override
  State<CWTab> createState() => _CWTabState();

  int getNb() {
    return ctx.designEntity?.getInt("tabCount", 2) ?? 2;
  }

  int getHeight() {
    return ctx.designEntity?.getInt("height", 100) ?? 100;
  }

  int getTabHeight() {
    return ctx.designEntity?.getInt("heightTabBar", 35) ?? 35;
  }

  @override
  initSlot(String path) {
    final nb = getNb();
    for (int i = 0; i < nb; i++) {
      addSlotPath('$path.Tab$i', SlotConfig('${ctx.xid}Tab$i'));
      addSlotPath('$path.Cont$i', SlotConfig('${ctx.xid}Cont$i'));
    }
  }
}

class _CWTabState extends StateCW<CWTab> {
  double heightHeader = 20;

  @override
  Widget build(BuildContext context) {
    heightHeader = widget.getTabHeight().toDouble();

    return DefaultTabController(
        length: widget.getNb(),
        child: LayoutBuilder(builder:
            (BuildContext context, BoxConstraints viewportConstraints) {
          double heightBody = -1;

          if (viewportConstraints.maxHeight != double.infinity) {
            heightBody = viewportConstraints.maxHeight - heightHeader - 2;
          }

          return Column(children: <Widget>[
            getTabsButton(),
            getTabsSlot(heightBody, viewportConstraints)
          ]);
        }));
  }

  SizedBox getTabsButton() {
    final List<Widget> listTab = <Widget>[];

    for (int i = 0; i < widget.getNb(); i++) {
      listTab.add(
          // icon: Icon(size:10,  Icons.access_alarm),
          Tab(
              height: heightHeader,
              child: CWSlot(
                  type: "selector",
                  key: GlobalKey(debugLabel: 'tab btn slot ${widget.ctx.xid}'),
                  ctx: widget.createChildCtx('Tab', i))));
    }

    return SizedBox(
      height: heightHeader + 2,
      child: ColoredBox(
          color: Theme.of(context).primaryColor,
          child: TabBar(
            tabs: listTab,
          )),
    );
  }

  Widget getTabsSlot(double fixedHeight, BoxConstraints viewportConstraints) {
    final List<Widget> listTab = <Widget>[];
    final nb = widget.getNb();
    for (int i = 0; i < nb; i++) {
      Widget slot;
      if (fixedHeight != -1) {
        slot = Container(
            constraints:
                BoxConstraints(minHeight: viewportConstraints.maxHeight),
            child: Column(children: [
              Expanded(
                  child: CWSlot(
                      type: "body",
                      key: GlobalKey(
                          debugLabel: 'tab cont slot ${widget.ctx.xid}'),
                      ctx: widget.createChildCtx('Cont', i)))
            ]));
      } else {
        slot = SingleChildScrollView(
            child: CWSlot(
                type: "body",
                key: GlobalKey(debugLabel: 'tab cont slot ${widget.ctx.xid}'),
                ctx: widget.createChildCtx('Cont', i)));
      }
      listTab.add(slot);
    }

    if (fixedHeight == -1) {
      // return SizedBox(
      //     height: widget.getHeight().toDouble(),
      //     child: TabBarView(children: listTab));
      return SizedBox(
          height: widget.getHeight().toDouble(),
          child: TabBarView(children: listTab));
    } else {
      return SizedBox(
          height: fixedHeight, child: TabBarView(children: listTab));
    }
  }
}
