import 'package:flutter/material.dart';

import '../core/widget/cw_core_widget.dart';


class CWText extends CWWidget {
  const CWText({
    super.key,
    required super.ctx,
  });

  @override
  State<CWText> createState() => _CWTextState();

  String getLabel() {
    return ctx.entityForFactory?.getString('label') ?? '[empty]';
  }

  @override
  initSlot(String path) {}
}

class _CWTextState extends StateCW<CWText> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.getLabel());
  }
}
