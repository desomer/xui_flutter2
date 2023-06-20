import 'package:flutter/material.dart';

import '../core/widget/cw_core_widget.dart';

// ignore: must_be_immutable
class CWText extends CWWidget {
  CWText({
    super.key,
    required super.ctx,
  });

  @override
  State<CWText> createState() => _CWTextState();

  String getLabel() {
    return ctx.entityForFactory?.getString('label') ?? 'vide';
  }

  @override
  initSlot(String path) {}
}

class _CWTextState extends State<CWText> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.getLabel());
  }
}
