import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_future.dart';
import '../core/widget/cw_core_slot.dart';
import '../designer/cw_factory.dart';
import 'cw_row.dart';

class CWList extends CWWidgetMap {
  CWList({super.key, required super.ctx}) {
    //print("create list ${ctx.xid} h=$hashCode");
  }

  @override
  State<CWList> createState() => _CwListState();

  @override
  initSlot(String path) {
    addSlotPath('$path[].Cont', SlotConfig('${ctx.xid}Cont'));
  }

  static initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget(
            "CWList", (CWWidgetCtx ctx) => CWList(key: ctx.getKey(), ctx: ctx))
        .addAttr('reorder', CDAttributType.CDbool)
        .addAttr('providerName', CDAttributType.CDtext);
  }

  bool getReorder() {
    return ctx.designEntity?.getBool("reorder", false) ?? false;
  }
}

//---------------------------------------------------------------
class _CwListState extends StateCW<CWList> {
  OverlayEntry? sticky;
  GlobalKey? stickyKey;
  final controller = ScrollController();

  @override
  void initState() {
    if (sticky != null) {
      sticky!.remove();
    }
    sticky = OverlayEntry(
      builder: (context) => stickyBuilder(context),
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      Overlay.of(context).insert(sticky!);
    });

    super.initState();
  }

  @override
  void dispose() {
    if (sticky != null) {
      sticky!.remove();
    }
    super.dispose();
  }

  GlobalKey ak = GlobalKey();
  GlobalKey rp = GlobalKey();

  Widget stickyBuilder(BuildContext context) {
    return AnimatedBuilder(
      key: rp,
      animation: controller, // on scroll
      builder: (_, child) {
        final keyContext = stickyKey?.currentContext;
        if (keyContext != null) {
          final box = keyContext.findRenderObject() as RenderBox;
          final pos = box.localToGlobal(Offset.zero);
          return AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              key: ak,
              top: pos.dy -3,
              left: pos.dx + box.size.width - 20,
              width: 30,
              height: box.size.height,
              child: IgnorePointer( child: Center(child : const Icon(Icons.arrow_right_sharp, size: 30))));
        }
        return Container();
      },
    );
  }

  getListView(int nbRow) {
    CWProvider? provider = CWProvider.of(widget.ctx);

    itemBuilder(context, index) {
      widget.setIdx(index);

      var rowState = InheritedStateContainer(
          key: GlobalKey(),
          index: index,
          arrayState: this,
          child: CWSlot(
              key: widget.ctx.getSlotKey('Cont$index', ''),
              ctx: widget.createInArrayCtx('Cont', null)));

      if (provider!.idxSelected == index) {
        stickyKey = rowState.key as GlobalKey<State<StatefulWidget>>?;
      }

      return InkWell(
          key: ObjectKey(provider.content[index]),
          onTap: () {
            rowState.selected(widget.ctx);
          },
          child: rowState);
    }

    return widget.getReorder()
        ? ReorderableListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: nbRow,
            itemBuilder: itemBuilder,
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                provider!.loader!.reorder(oldIndex, newIndex);
              });
            },
          )
        : ListView.builder(
            controller: controller,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: nbRow,
            itemBuilder: itemBuilder,
          );
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

//---------------------------------------------------------------
class InheritedStateContainer extends InheritedWidget {
  // Data is your entire state.
  final StateCW<CWWidgetMap> arrayState;
  final CwRowState? rowState;
  final int? index;

  final GlobalKey rowKey = GlobalKey();

  // You must pass through a child and your state.
  InheritedStateContainer(
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
        if (arrayState is _CwListState) {
          // affiche la ligne selectionné
          (arrayState as _CwListState).stickyKey =
              key as GlobalKey<State<StatefulWidget>>?;
          // ignore: invalid_use_of_protected_member
          (arrayState as _CwListState).rp.currentState?.setState(() {});
        }
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
