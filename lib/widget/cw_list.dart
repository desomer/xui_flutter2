import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_future.dart';
import '../core/widget/cw_core_slot.dart';
import '../designer/cw_factory.dart';
import '../designer/designer_query.dart';
import 'cw_array_row.dart';
import 'cw_toolkit.dart';

// ignore: must_be_immutable
class CWList extends CWWidgetMap {
  CWList({super.key, required super.ctx});

  @override
  State<CWList> createState() => _CwListState();

  @override
  void initSlot(String path) {
    addSlotPath('$path[].Cont', SlotConfig('${ctx.xid}Cont'));
  }

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget(
            'CWList', (CWWidgetCtx ctx) => CWList(key: ctx.getKey(), ctx: ctx))
        .addAttr('reorder', CDAttributType.bool)
        .addAttr('providerName', CDAttributType.text);
  }

  bool getReorder() {
    return ctx.designEntity?.getBool('reorder', false) ?? false;
  }

  Rect? selectorPos;
}

//---------------------------------------------------------------
class _CwListState extends StateCW<CWList> {
  OverlayEntry? sticky;
  final controller = ScrollController();

  @override
  void initState() {
    initPosObservable();

    super.initState();
  }

  @override
  void dispose() {
    if (sticky != null) {
      sticky!.remove();
    }
    super.dispose();
  }

  void initPosObservable() {
    if (sticky != null) {
      sticky!.remove();
    }
    sticky = OverlayEntry(
      builder: (context) => posCalculatorBuilder(context),
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      Overlay.of(context).insert(sticky!);
    });
  }

  GlobalKey keyPosCalculator = GlobalKey();
  GlobalKey keyListOrigin = GlobalKey();
  GlobalKey keySelector = GlobalKey();
  GlobalKey? keyObserve;

  Widget posCalculatorBuilder(BuildContext context) {
    return AnimatedBuilder(
      key: keyPosCalculator,
      animation: controller, // on scroll
      builder: (_, child) {
        final keyContext = keyObserve?.currentContext;
        widget.selectorPos = null;
        if (keyContext != null) {
          widget.selectorPos =
              CwToolkit.getPositionRect(keyObserve!, keyListOrigin);
          Future.delayed(const Duration(milliseconds: 1), () {
            keySelector.currentState?.setState(() {});
          });
        }
        return Container();
      },
    );
  }

  void changeObserve(GlobalKey key) {
    keyObserve = key;
    keyPosCalculator.currentState?.setState(() {});
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
      debugPrint('accept list');
      
     // FormBuilder().createForm(widget, item.query);

      /// ArrayBuilder().createArray(widget, item.query);
    });
  }

  static const double borderDrag = 10;

  Widget getDropQuery(double h) {
    return getDropZone(Container(
        margin: const EdgeInsets.fromLTRB(
            borderDrag, borderDrag, borderDrag, borderDrag),
        height: h,
        child: DottedBorder(
            color: Colors.grey,
            dashPattern: const <double>[6, 4],
            strokeWidth: 2,
            child: const Center(
                child: IntrinsicWidth(
                    child: Row(children: [
              Text('Drag query here'),
              Icon(Icons.filter_alt)
            ]))))));
  }

  Widget getListView(int nbRow) {
    CWProvider? provider = CWProvider.of(widget.ctx);

    if (nbRow == -1) {
      return getDropQuery(50);
    }

    //////////////////////////////////////////////////////
    InkWell itemBuilder(context, index) {
      widget.setIdx(index);

      var rowState = InheritedStateContainer(
          key: GlobalKey(),
          index: index,
          arrayState: this,
          child: CWSlot(
              type: 'dataCell',
              key: widget.ctx.getSlotKey('Cont$index', ''),
              ctx: widget.createInArrayCtx('Cont', null)));

      if (provider!.getData().idxSelected == index) {
        keyObserve = rowState.key as GlobalKey<State<StatefulWidget>>?;
      }

      return InkWell(
          key: ObjectKey(provider.content[index]),
          onTap: () {
            rowState.selected(widget.ctx);
          },
          child: rowState);
    }

    //////////////////////////////////////////////////////

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
    var futureData = widget.initFutureDataOrNot(CWProvider.of(widget.ctx), widget.ctx);

    Widget getContent(int ok) {
      var provider = CWProvider.of(widget.ctx);
      widget.setProviderDataOK(provider, ok);
      return Stack(key: keyListOrigin, children: [
        getListView(ok),
        CWListSelector(key: keySelector, list: widget)
      ]);
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

class CWListSelector extends StatefulWidget {
  const CWListSelector({required this.list, Key? key}) : super(key: key);
  final CWList list;

  @override
  State<CWListSelector> createState() => _CWListSelectorState();
}

class _CWListSelectorState extends State<CWListSelector> {
  GlobalKey ak = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (widget.list.selectorPos == null) return Container();
    Rect box = widget.list.selectorPos!;
    return AnimatedPositioned(
        duration: const Duration(milliseconds: 100),
        key: ak,
        top: box.top - 3,
        left: box.left + box.width - 20,
        width: 30,
        height: box.height,
        child: const IgnorePointer(
            child: Center(child: Icon(Icons.arrow_right_sharp, size: 30))));
  }
}

//---------------------------------------------------------------
class InheritedStateContainer extends InheritedWidget {
  // Data is your entire state.
  final StateCW<CWWidgetMap> arrayState;
  final CWArrayRowState? rowState;
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
      if (provider.getData().idxSelected != index) {
        provider.getData().idxSelected = index!;
        provider.doAction(ctx, ctxWE, CWProviderAction.onRowSelected);
        if (arrayState is _CwListState) {
          // affiche la ligne selectionné
          (arrayState as _CwListState).changeObserve(key as GlobalKey);
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
