import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/cw_factory.dart';

class CWText extends CWWidgetMap {
  const CWText({
    super.key,
    required super.ctx,
  });

  static initFactory(CWCollection c) {
    c
        .addWidget(
            (CWText), (CWWidgetCtx ctx) => CWText(key: ctx.getKey(), ctx: ctx))
        .addAttr('label', CDAttributType.CDtext)
        .addAttr('textColor', CDAttributType.CDtext);
  }

  @override
  State<CWText> createState() => _CWTextState();

  @override
  String getLabel() {
    if (ctx.designEntity?.getString('bind') != null) {
      return getValue();
    } else {
      return super.getLabel();
    }
  }

  @override
  initSlot(String path) {}
}

class _CWTextState extends StateCW<CWText> {
  @override
  Widget build(BuildContext context) {
    widget.initRow(context);
    return Text(softWrap: false, overflow: TextOverflow.fade, widget.getLabel());
  }
}
