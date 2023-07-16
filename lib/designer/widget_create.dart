import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';

class WidgetDrag extends StatefulWidget {
  const WidgetDrag({required this.provider, Key? key}) : super(key: key);

  final CWProvider provider;

  @override
  State<WidgetDrag> createState() => _WidgetDragState();
}

class _WidgetDragState extends State<WidgetDrag> {
  Widget getDropZone(Widget child) {
    return DragTarget<String>(
        builder: (context, candidateItems, rejectedItems) {
      return AnimatedScale(
          scale: candidateItems.isEmpty ? 1 : 0.95,
          duration: const Duration(milliseconds: 100),
          child: child);
    }, onWillAccept: (item) {
      return true;
    }, onAccept: (item) {
      CWWidgetEvent ctxWE = CWWidgetEvent();
      ctxWE.action = CWProviderAction.onInsertNone.toString();
      ctxWE.provider = widget.provider;
      ctxWE.payload = item;
      widget.provider.doAction(null, ctxWE, CWProviderAction.onInsertNone);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: getDropZone(DottedBorder(
          color: Colors.grey,
          dashPattern: const <double>[4, 4],
          strokeWidth: 2,
          child: const Center(
              child: Text(
            "Drag new attribut",
            style: TextStyle(color: Colors.grey),
          )))),
    );
  }
}

class WidgetAddBtn extends StatefulWidget {
  const WidgetAddBtn({required this.provider, required this.loader, Key? key})
      : super(key: key);

  final CWProvider provider;
  final CWWidgetLoaderCtx loader;

  @override
  State<WidgetAddBtn> createState() => _WidgetAddBtnState();
}

class _WidgetAddBtnState extends State<WidgetAddBtn> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          CWWidgetEvent ctxWE = CWWidgetEvent();
          ctxWE.action = CWProviderAction.onInsertNone.toString();
          ctxWE.provider = widget.provider;
          widget.provider.doAction(null, ctxWE, CWProviderAction.onInsertNone);
          Future.delayed(const Duration(milliseconds: 100), () {
            widget.loader.factory.mapWidgetByXid["Col0"]!.repaint();
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          child: DottedBorder(
              color: Colors.grey,
              dashPattern: const <double>[4, 4],
              strokeWidth: 2,
              child: const Center(
                  child: Text(
                "+",
                style: TextStyle(color: Colors.grey),
              ))),
        ));
  }
}
