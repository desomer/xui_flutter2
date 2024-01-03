import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/cw_factory.dart';
import 'cw_list.dart';

class CWText extends CWWidgetMapLabel {
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
        .addAttr('icon', CDAttributType.one, tname: 'icon')
        ;
  }

  @override
  State<CWText> createState() => _CWTextState();

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
    SlotConfig? slotConfig =
        widget.ctx.factory.mapSlotConstraintByPath[widget.ctx.pathWidget];
    String type = slotConfig?.slot?.type ?? '';

    Map<String, dynamic>? v = widget.getIcon();
    bool isTab = type == 'tab';

    Widget? icon;
    if (v != null) {
      IconData? ic = deserializeIcon(v);
      icon = Icon(ic);
    }

    var label = widget.getLabel(icon!=null?'':'[label]');
    Widget? text;

    if (label != '' || icon == null) {
      text = Text(
        softWrap: false,
        overflow: TextOverflow.fade,
        label,
        style: TextStyle(color: widget.getColor('textColor')),
      );
    }

    var mode = isTab ? 'col' : 'row';
    if (icon != null && mode == 'row' && text != null) {
      text = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          text,
        ],
      );
    } else if (icon != null && mode == 'col' && text != null) {
      text = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          text,
        ],
      );
    } else if (text == null && icon != null) {
      text = icon;
    }

    if (row != null) widget.setDisplayRow(row);

    return getMinDesignBox(text!);
  }

  Widget getMinDesignBox(Widget child) {
    return widget.ctx.factory.loader.mode == ModeRendering.design
        ? ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 30), child: child)
        : child;
  }
}
