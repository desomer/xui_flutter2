import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:xui_flutter/widget/cw_selector.dart';

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
        .addCustomValue('bindEnable', true)
        .addAttr('textColor', CDAttributType.one,
            tname: CWSelectorType.color.name)
        .addAttr('icon', CDAttributType.one, tname: CWSelectorType.icon.name)
        .addAttr('_style_', CDAttributType.one, tname: CWSelectorType.style.name);
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
    //Text('\$8.99', style: Theme.of(context).textTheme.bodyLarge);
    /*

    'displayLarge', displayLarge, defaultValue: defaultTheme.displayLarge));
    properties.add(DiagnosticsProperty<TextStyle>('displayMedium', displayMedium, defaultValue: defaultTheme.displayMedium));
    properties.add(DiagnosticsProperty<TextStyle>('displaySmall', displaySmall, defaultValue: defaultTheme.displaySmall));
    properties.add(DiagnosticsProperty<TextStyle>('headlineLarge', headlineLarge, defaultValue: defaultTheme.headlineLarge));
    properties.add(DiagnosticsProperty<TextStyle>('headlineMedium', headlineMedium, defaultValue: defaultTheme.headlineMedium));
    properties.add(DiagnosticsProperty<TextStyle>('headlineSmall', headlineSmall, defaultValue: defaultTheme.headlineSmall));
    properties.add(DiagnosticsProperty<TextStyle>('titleLarge', titleLarge, defaultValue: defaultTheme.titleLarge));
    properties.add(DiagnosticsProperty<TextStyle>('titleMedium', titleMedium, defaultValue: defaultTheme.titleMedium));
    properties.add(DiagnosticsProperty<TextStyle>('titleSmall', titleSmall, defaultValue: defaultTheme.titleSmall));
    properties.add(DiagnosticsProperty<TextStyle>('bodyLarge', bodyLarge, defaultValue: defaultTheme.bodyLarge));
    properties.add(DiagnosticsProperty<TextStyle>('bodyMedium', bodyMedium, defaultValue: defaultTheme.bodyMedium));
    properties.add(DiagnosticsProperty<TextStyle>('bodySmall', bodySmall, defaultValue: defaultTheme.bodySmall));
    properties.add(DiagnosticsProperty<TextStyle>('labelLarge', labelLarge, defaultValue: defaultTheme.labelLarge));
    properties.add(DiagnosticsProperty<TextStyle>('labelMedium', labelMedium, defaultValue: defaultTheme.labelMedium));
    properties.add(DiagnosticsProperty<TextStyle>('labelSmall', labelSmall, defaultValue: defaultTheme.labelSmall));
    */

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

    var label = widget.getLabel(icon != null ? '' : '[label]');
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
