import 'package:flutter/material.dart';

import 'cw_builder.dart';
import 'cw_slot.dart';

// ignore: must_be_immutable
class CWTab extends CWWidget {
  CWTab({
    super.key,
    required this.nb,
    required super.ctx,
  });

  final int nb;

  @override
  State<CWTab> createState() => _CWTabState();
}

class _CWTabState extends State<CWTab> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: widget.nb,
        child: LayoutBuilder(builder:
            (BuildContext context, BoxConstraints viewportConstraints) {
          return Column(children: <Widget>[
            getTabsButton(),
            getTabsSlot(viewportConstraints.maxHeight - 22)
          ]);
        }));
  }

  SizedBox getTabsButton() {
    final List<Widget> listTab = <Widget>[];

    for (int i = 0; i < widget.nb; i++) {
      final CWWidgetCtx ctxW = CWWidgetCtx('${widget.ctx.xid}Tab$i',
          widget.ctx.factory, '${widget.ctx.path}.Tab$i', widget.ctx.ctxData);
      listTab.add(Tab(height: 20, child: CWSlot(ctx: ctxW)));
    }

    return SizedBox(
      height: 22,
      child: ColoredBox(
          color: Colors.blueGrey,
          child: TabBar(
            tabs: listTab,
          )),
    );
  }

  SizedBox getTabsSlot(double h) {
    final List<Widget> listTab = <Widget>[];

    for (int i = 0; i < widget.nb; i++) {
      final CWWidgetCtx ctxW = CWWidgetCtx('${widget.ctx.xid}Cont$i',
          widget.ctx.factory, '${widget.ctx.path}.Cont$i', widget.ctx.ctxData);
      final CWSlot slot = CWSlot(ctx: ctxW);

      listTab.add(slot);
    }

    return SizedBox(height: h, child: TabBarView(children: listTab));
  }

  // Tab getTabButton() {
  //   return const Tab(
  //     height: 20,
  //     icon: Icon(Icons.directions_bike, size: 18),
  //   );
  // }
}
