import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:xui_flutter/core/data/core_data.dart';

import '../core/data/core_provider.dart';
import '../core/widget/cw_core_widget.dart';
import 'cw_array.dart';
import 'cw_list.dart';

final log = Logger('CWArrayRow');

class CWArrayRow extends StatefulWidget {

  static double heightRow = 26;

  const CWArrayRow(
      {required this.rowIdx,
      //required this.children,
      required this.stateArray,
      required this.getRowBuilder,
      required super.key});
  final int rowIdx;
  //final List<Widget> children;
  final StateCW<CWArray> stateArray;
  final Function(CWArrayRowState) getRowBuilder;

  @override
  State<CWArrayRow> createState() => CWArrayRowState();

  void selected(CWWidgetCtx ctx) {
    CWWidgetEvent ctxWE = CWWidgetEvent();
    ctxWE.action = CWProviderAction.onRowSelected.toString();
    CWProvider? provider = CWProvider.of(stateArray.widget.ctx);
    print('selected row $rowIdx');
    if (provider != null) {
      ctxWE.provider = provider;
      ctxWE.payload = rowIdx;
      ctxWE.loader = stateArray.widget.ctx.loader;
      if (provider.getData().idxSelected != rowIdx) {
        provider.getData().idxSelected = rowIdx;
        provider.doAction(ctx, ctxWE, CWProviderAction.onRowSelected);
      }
    }
  }
}

class CWArrayRowState extends State<CWArrayRow> {
  @override
  void initState() {
    super.initState();
    //widget.stateArray.widget.listState[widget.rowIdx] = this;
    //print("add row ${widget.rowIdx}");
  }

  @override
  void dispose() {
    super.dispose();
    log.finest('dispose CWArrayRow ${widget.rowIdx}');
    //widget.stateArray.widget.listState.remove(widget.rowIdx);
    for (var element in mapFocus.entries) {
      element.value.dispose();
    }
    mapFocus.clear();
  }

  Map<String, FocusNode> mapFocus = {};

  @override
  Widget build(BuildContext context) {
    List<Widget> listSlot = widget.getRowBuilder(this);

    var rowState = InheritedStateContainer(
        key: ValueKey(widget.rowIdx),
        index: widget.rowIdx,
        arrayState: widget.stateArray,
        rowState: this,
        child: Stack(children: [
          Row(
            children: listSlot,
          ),
          IgnorePointer(child: LayoutBuilder(
            builder: (context, constraints) {
              CWProvider? provider =
                  CWProvider.of(widget.stateArray.widget.ctx);

              //debugPrint('get array provider ${provider!.name} hash = ${provider.getData().hashCode}');

              CoreDataEntity r = provider!.content[widget.rowIdx];

              return CustomPaint(
                size: Size(constraints.maxWidth, 20),
                painter:
                    r.operation == CDAction.delete ? RowDeletePainter() : null,
              );
            },
          ))
        ]));
    return rowState;
  }
}

class RowDeletePainter extends CustomPainter {
  //         <-- CustomPainter class
  @override
  void paint(Canvas canvas, Size size) {
    const p1 = Offset(5, 14);
    final p2 = Offset(size.width - 30, 14);
    final paint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 2;
    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
