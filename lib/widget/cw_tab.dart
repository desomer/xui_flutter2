import 'package:flutter/material.dart';

import '../core/widget/cw_core_slot.dart';
import '../core/widget/cw_core_widget.dart';

// ignore: must_be_immutable
class CWTab extends CWWidget {
  CWTab({
    super.key,
    required super.ctx,
  });

  @override
  State<CWTab> createState() => _CWTabState();

  int getNb() {
    return ctx.entity?.getInt("nb", 2) ?? 2;
  }

  @override
  initSlot(String path) {
    final nb = getNb();
    for (int i = 0; i < nb; i++) {
      addSlotPath('$path.Tab$i', '${ctx.xid}Tab$i');
      addSlotPath('$path.Cont$i', '${ctx.xid}Cont$i');
    }
  }
}

class _CWTabState extends State<CWTab> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: widget.getNb(),
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

    for (int i = 0; i < widget.getNb(); i++) {
      listTab.add(
          Tab(height: 20, child: CWSlot(ctx: widget.createChildCtx('Tab', i))));
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
    final nb = widget.getNb();
    for (int i = 0; i < nb; i++) {
      final CWWidgetCtx ctxW = CWWidgetCtx('${widget.ctx.xid}Cont$i',
          widget.ctx.factory, '${widget.ctx.pathWidget}.Cont$i');
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
