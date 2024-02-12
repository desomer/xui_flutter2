import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/data/core_repository.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import '../widget/cw_list.dart';

class WidgetDrag extends StatefulWidget {
  const WidgetDrag({required this.provider, super.key});

  final CWRepository provider;

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
      ctxWE.action = CWRepositoryAction.onStateNone.toString();
      ctxWE.provider = widget.provider;
      ctxWE.payload = item;
      widget.provider.doAction(null, ctxWE, CWRepositoryAction.onStateNone);
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
            'Drag new attribut',
            style: TextStyle(color: Colors.grey),
          )))),
    );
  }
}

class WidgetAddBtn extends StatefulWidget {
  const WidgetAddBtn(
      {required this.provider,
      required this.loader,
      this.repaintXid,
      super.key});

  final CWRepository provider;
  final CWAppLoaderCtx loader;
  final String? repaintXid;

  @override
  State<WidgetAddBtn> createState() => _WidgetAddBtnState();
}

class _WidgetAddBtnState extends State<WidgetAddBtn> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          widget.provider.doEvent(CWRepositoryAction.onStateNone, widget.loader,
              repaintXid: widget.repaintXid);
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          child: DottedBorder(
              color: Colors.grey,
              dashPattern: const <double>[4, 4],
              strokeWidth: 2,
              child: const Center(
                  child: Text(
                '+',
                style: TextStyle(color: Colors.grey),
              ))),
        ));
  }
}

class WidgetDeleteBtn extends StatefulWidget {
  const WidgetDeleteBtn({super.key});

  @override
  State<WidgetDeleteBtn> createState() => _WidgetDeleteBtnState();
}

class _WidgetDeleteBtnState extends State<WidgetDeleteBtn> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: const Padding(
        padding: EdgeInsets.all(2),
        child: Icon(Icons.delete_forever, size: 20),
      ),
      onTap: () {
        var r = context.getInheritedWidgetOfExactType<InheritedRow>();

        var provider = CWRepository.of(r!.arrayState.widget.ctx);
        provider!.content[r.index!].operation = CDAction.delete;
        provider.doEvent(
            CWRepositoryAction.onStateDelete, r.arrayState.widget.ctx.loader, row: r);
        provider.doEvent(
            CWRepositoryAction.onValidateEntity, r.arrayState.widget.ctx.loader, row: r);            
        //r.repaintRow(r.arrayState.widget.ctx);
      },
    );
  }
}
