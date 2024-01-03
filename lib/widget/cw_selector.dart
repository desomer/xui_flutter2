import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/widget/cw_container_form.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../designer/cw_factory.dart';
import 'cw_action.dart';

class CWSelector extends CWWidgetMapValue with CWActionManager {
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
        .addAttr('type', CDAttributType.text)
        .addAttr('_idAction_', CDAttributType.text);
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
    String type = widget.ctx.designEntity!.value['type'];
    if (type == 'Bind') {
      return getBindBtn(context);
    }

    return Container(
        padding: EdgeInsets.fromLTRB(5, type=='provider'?0:5, 5, 5),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 0.5, color: Theme.of(context).dividerColor))),
        child: Row(children: getTypeContent(type)));
  }

  Tooltip getBindBtn(BuildContext context) {
    String nameAttr = '';
    var provider = CWProvider.of(widget.ctx);
    var e = provider?.getDisplayedEntity();
    var v = e?.value[widget.ctx.designEntity!.value[iDBind]];
    if (v != null) {
      var provBind =
          CWApplication.of().loaderDesigner.getProvider(v[iDProviderName]);
      var attrName = provBind?.getAttrName(v[iDBind]);
      if (attrName != null) {
        nameAttr = '$attrName @ ${provBind!.getQueryName()}';
      }
    }
    return Tooltip(
        message: nameAttr,
        padding: const EdgeInsets.all(8.0),
        preferBelow: false,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              )),
          onPressed: () {
            widget.doAction(context, widget, widget.ctx.designEntity?.value);
          },
          child: Text(nameAttr.isNotEmpty ? '@' : ''),
        ));
  }

  List<Widget> getTypeContent(String type) {
    switch (type) {
      case 'provider':
        return getProviderContent();
      case 'color':
        Map<String, dynamic>? oneValue = widget.getMapOne();
        return getColorContent(oneValue);
      case 'icon':
        Map<String, dynamic>? oneValue = widget.getMapOne();
        return getIconContent(oneValue);
      case 'info':
        return [
          SizedBox(
              height: CWForm.getHeightRow(widget) - 10,
              child: Text(widget.getLabel('[label]')))
        ];
      default:
        return [Container()];
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
      Text(widget.getLabel('[label]')),
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
      Text(widget.getLabel('[label]')),
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

  List<Widget> getProviderContent() {
    String provID = widget.getMapString();

    CWProvider? provider =
        CWApplication.of().loaderDesigner.factory.mapProvider[provID];

    var data = provider?.getQueryName() ?? 'no provider';
    return [
      SizedBox(
          height: CWForm.getHeightRow(widget)-5,
          width: 200,
          child: TextFormField(
              readOnly: true,
              initialValue: data,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  labelText: 'Provider',
                  contentPadding: EdgeInsets.fromLTRB(5, 0, 5, 0))))
    ];
  }
}
