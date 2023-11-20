import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
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
  Color? _color;
  TextEditingController edit = TextEditingController();

  @override
  void initState() {
    super.initState();
    edit.addListener(() {
      Map<String, dynamic>? oneValue = widget.getMapOne();
      if (oneValue?['color'] != edit.text) {
        if (edit.text.length == 8) {
          oneValue?['color'] = edit.text;
          widget.setValue(oneValue);
        } else if (edit.text.isEmpty) {
          widget.setValue(null);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? oneValue = widget.getMapOne();

    return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 0.5, color: Theme.of(context).dividerColor))),
        child: Row(children: getTypeContent(oneValue)));
  }

  List<Widget> getTypeContent(Map<String, dynamic>? oneValue) {
    switch (widget.ctx.designEntity!.value['type']) {
      case 'color':
        return getColorContent(oneValue);
      default:
        return getIconContent(oneValue);
    }
  }

  //-------------------------------------------------------------------
  List<Widget> getColorContent(Map<String, dynamic>? oneValue) {
    if (oneValue != null) {
      _color = Color(int.parse(oneValue['color'], radix: 16));
      edit.text = oneValue['color'];
    } else {
      _color = null;
      edit.text = '';
    }
    return [
      Text(widget.getLabel()),
      const SizedBox(width: 20),
      SizedBox(
          width: 100,
          child: TextField(
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.fromLTRB(5, 0, 5, 0)),
              controller: edit)),
      Container(width: 20, height: 20, color: _color),
      const Spacer(),
      InkWell(
        onTap: _pickColor,
        child: const Icon(Icons.color_lens),
      )
    ];
  }

  void _pickColor() async {
    Color? selColor;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: MaterialColorPicker(
                onColorChange: (Color color) {
                  selColor = color;
                },
                onMainColorChange: (ColorSwatch<dynamic>? color) {},
                selectedColor: _color),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Ok'),
                onPressed: () {
                  _color = selColor;
                  if (_color != null) {
                    var v = {
                      'color': _color!.value.toRadixString(16).padLeft(8, '0')
                    };
                    widget.setValue(v);
                  } else {
                    widget.setValue(null);
                  }
                  setState(() {});
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  //---------------------------------------------------------------------------------------
  List<Widget> getIconContent(Map<String, dynamic>? oneValue) {
    if (oneValue != null) {
      IconData? ic = deserializeIcon(oneValue);
      _icon = Icon(ic);
    }
    return [
      Text(widget.getLabel()),
      const SizedBox(width: 20),
      _icon ?? Container(),
      const Spacer(),
      InkWell(
        onTap: _pickIcon,
        child: const Icon(Icons.apps),
      )
    ];
  }

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
}
