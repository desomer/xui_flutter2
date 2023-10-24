import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../designer/cw_factory.dart';

class CWSelector extends CWWidgetMap {
  const CWSelector({super.key, required super.ctx});

  @override
  State<CWSelector> createState() => _CWSelectorState();

  @override
  void initSlot(String path) {}

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget('CWSelector',
            (CWWidgetCtx ctx) => CWSelector(key: ctx.getKey(), ctx: ctx))
        .addAttr('label', CDAttributType.text)
        .addAttr('type', CDAttributType.text);
  }
}

class _CWSelectorState extends StateCW<CWSelector> {
  Icon? _icon;

  void _pickIcon() async {
    IconData? icon = await FlutterIconPicker.showIconPicker(context,
        iconPackModes: [IconPack.material]);

    _icon = Icon(icon);
    setState(() {});

    if (icon != null) {
      Map<String, dynamic>? map =
          serializeIcon(icon, iconPack: IconPack.material);
      debugPrint('Picked Icon:  ${map!['key']}');
      widget.setValue(map);
      //var ic = deserializeIcon(map!);
    } else {
      widget.setValue(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? v = widget.getMapOne();
    if (v!=null) {
      IconData? ic = deserializeIcon(v);
      _icon = Icon(ic);
    }

    return Row(children: [
      Text(' icon', style: TextStyle(color: Colors.grey.shade400)),
      const SizedBox(width: 20),
      _icon ?? Container(),
      const Spacer(),
      InkWell(
        onTap: _pickIcon,
        child: const Icon(Icons.apps),
      )
    ]);
  }
}
