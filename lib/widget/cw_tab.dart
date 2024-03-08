import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_slot.dart';
import '../core/widget/cw_core_widget.dart';
import '../core/widget/cw_factory.dart';

class CWTab extends CWWidget {
  const CWTab({
    super.key,
    required super.ctx,
  });

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget(
            'CWTab', (CWWidgetCtx ctx) => CWTab(key: ctx.getKey(), ctx: ctx))
        .addAttr('tabCount', CDAttributType.int)
        .withAction(AttrActionDefault(2))
        .addAttr('heightTabBar', CDAttributType.int)
        .addAttr('height', CDAttributType.int);
  }

  @override
  State<CWTab> createState() => _CWTabState();

  int getNb() {
    return ctx.designEntity?.getInt('tabCount', 2) ?? 2;
  }

  int getHeight() {
    return ctx.designEntity?.getInt('height', 100) ?? 100;
  }

  int getTabHeight() {
    return ctx.designEntity?.getInt('heightTabBar', 44) ?? 44;
  }

  @override
  void initSlot(String path, ModeParseSlot mode) {
    final nb = getNb();
    for (int i = 0; i < nb; i++) {
      addSlotPath('$path.Tab$i', SlotConfig(XidBuilder(tag:'Tab', idx: i), ctx.xid, ), mode);
      addSlotPath('$path.Cont$i', SlotConfig(XidBuilder(tag:'Cont', idx: i), ctx.xid ), mode);
    }
  }
}

class _CWTabState extends StateCW<CWTab> {
  double heightHeader = -1;

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
            getTabsContent(heightBody, viewportConstraints)
          ]);
        }));
  }

  SizedBox getTabsButton() {
    final List<Widget> listTab = <Widget>[];

    for (int i = 0; i < widget.getNb(); i++) {
      var createChildCtx = widget.createChildCtx(widget.ctx, 'Tab', i);
      // var w = createChildCtx.getWidgetInSlot();

      listTab.add(
          // icon: Icon(size:10,  Icons.access_alarm),
          Tab(
              height: heightHeader,
              child: CWSlot(
                type: 'tab',
                key: GlobalKey(debugLabel: 'tab btn slot ${widget.ctx.xid}'),
                ctx: createChildCtx,
                slotAction: SlotTabAction(),
              )));
    }

    return SizedBox(
      height: heightHeader + 2,
      child: TabBar(
        tabs: listTab,
      ),
    );
  }

  Widget getTabsContent(
      double fixedHeight, BoxConstraints viewportConstraints) {
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
                type: 'body',
                key: GlobalKey(debugLabel: 'tab cont slot ${widget.ctx.xid}'),
                ctx: widget.createChildCtx(widget.ctx, 'Cont', i),
                slotAction: SlotTabAction(),
              ))
            ]));
      } else {
        slot = SingleChildScrollView(
            child: CWSlot(
          type: 'body',
          key: GlobalKey(debugLabel: 'tab cont slot ${widget.ctx.xid}'),
          ctx: widget.createChildCtx(widget.ctx, 'Cont', i),
          slotAction: SlotTabAction(),
        ));
      }
      listTab.add(slot);
    }

    if (fixedHeight == -1) {
      return SizedBox(
          height: widget.getHeight().toDouble(),
          child: TabBarView(children: listTab));
    } else {
      return SizedBox(
          height: fixedHeight, child: TabBarView(children: listTab));
    }
  }
}

class SlotTabAction extends SlotAction {
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
    return true;
  }

  @override
  bool canAddBottom() {
    return true;
  }

  @override
  bool addTop(CWWidgetCtx ctx) {
    return true;
  }

  @override
  bool canAddTop() {
    return true;
  }

  @override
  bool canMoveBottom() {
    return true;
  }

  @override
  bool moveBottom(CWWidgetCtx ctx) {
    return true;
  }

  @override
  bool canMoveTop() {
    return true;
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
    return true;
  }

  @override
  bool canAddRight() {
    return true;
  }

  @override
  bool canMoveLeft() {
    return true;
  }

  @override
  bool canMoveRight() {
    return true;
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
