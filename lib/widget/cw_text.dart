import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/cw_factory.dart';
import 'cw_list.dart';

class CWText extends CWWidgetMap {
  const CWText({
    super.key,
    required super.ctx,
  });

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget(
            'CWText', (CWWidgetCtx ctx) => CWText(key: ctx.getKey(), ctx: ctx))
        .addAttr('label', CDAttributType.text)
        .addAttr('textColor', CDAttributType.one, tname: 'color')
        .addAttr('providerName', CDAttributType.text)
        .addAttr('bind', CDAttributType.text);
  }

  @override
  State<CWText> createState() => _CWTextState();

  @override
  String getLabel() {
    if (ctx.designEntity?.getString('bind') != null) {
      return getMapString();
    } else {
      return super.getLabel();
    }
  }

  @override
  void initSlot(String path) {}
}

class _CWTextState extends StateCW<CWText> {
  InheritedStateContainer? row;

  @override
  void initState() {
    super.initState();
    row = widget.getRowState(context);
  }

  @override
  Widget build(BuildContext context) {
    if (row != null) widget.setDisplayRow(row);
    return getMinDesignBox(Text(
      softWrap: false,
      overflow: TextOverflow.fade,
      widget.getLabel(),
      style: TextStyle(color: widget.getColor('textColor')),
    ));
  }

  Widget getMinDesignBox(Widget child) {
    return widget.ctx.factory.loader.mode == ModeRendering.design
        ? ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 30), child: child)
        : child;
  }
}
