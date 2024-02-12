import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/db_icon_icons.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/widget/cw_container_form.dart';

import '../core/data/core_data.dart';
import '../core/data/core_repository.dart';
import '../core/widget/cw_factory.dart';
import '../designer/designer_selector_behaviour.dart';
import 'cw_action.dart';

enum CWSelectorType {
  provider,
  bind,
  color,
  icon,
  info,
  behaviour,
  style,
  slider
}

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
  double? doubleValue;
  TextEditingController edit = TextEditingController();

  @override
  void initState() {
    super.initState();
    String type = widget.ctx.designEntity!.value['type'];
    if (type == CWSelectorType.color.name) {
      edit.addListener(() {
        Map<String, dynamic>? oneValue = widget.getMapOne(iDBind);
        if (oneValue?['color'] != edit.text) {
          if (edit.text.length == 8) {
            oneValue?['color'] = edit.text;
            widget.setValue(oneValue);
          } else if (edit.text.isEmpty) {
            widget.setValue(null);
          }
        }
      });
    } else if (type == CWSelectorType.slider.name) {
      edit.addListener(() {
        double? d = widget.getMapDouble();
        if ((d?.toInt().toString() ?? '') != edit.text) {
          widget.setValue(edit.text);
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String type = widget.ctx.designEntity!.value['type'];
    if (type == 'bind') {
      return getBindBtn(context);
    }

    return Container(
        padding: EdgeInsets.fromLTRB(
            5, type == CWSelectorType.provider.name ? 0 : 5, 5, 5),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 0.5, color: Theme.of(context).dividerColor))),
        child: Row(children: getTypeContent(type)));
  }

  Tooltip getBindBtn(BuildContext context) {
    String nameAttr = '';
    var provider = CWRepository.of(widget.ctx);
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
          child: nameAttr.isNotEmpty
              ? const Text('@')
              : Icon(Icons.functions_rounded,
                  size: 15, color: Theme.of(context).disabledColor),
        ));
  }

  List<Widget> getTypeContent(String type) {
    switch (type) {
      case 'provider':
        return getProviderContent();
      case 'slider':
        return getSliderContent();
      case 'color':
        Map<String, dynamic>? oneValue = widget.getMapOne(iDBind);
        return getColorContent(oneValue);
      case 'icon':
        Map<String, dynamic>? oneValue = widget.getMapOne(iDBind);
        return getIconContent(oneValue);
      case 'info':
        return [
          SizedBox(
              height: CWForm.getHeightRow(widget) - 10,
              child: Text(widget.getLabel('[label]')))
        ];
      case 'behaviour':
        return [
          SizedBox(
              height: CWForm.getHeightRow(widget) - 10,
              child: Text(widget.getLabel('[label]'))),
          const Spacer(),
          InkWell(
            onTap: _pickBehaviour,
            child: const Icon(Icons.video_settings_rounded),
          )
        ];
      case 'style':
        return [
          SizedBox(
              height: CWForm.getHeightRow(widget) - 10,
              child: Text(widget.getLabel('[label]'))),
          const Spacer(),
          const InkWell(
            child: Icon(Icons.style_outlined),
          )
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

    IconData? icon = widget.ctx.designEntity?.value['customValue']?['icon'];
    List<Widget> ret = [];
    if (icon != null) ret.addAll([Icon(icon), const SizedBox(width: 5)]);

    ret.addAll([
      Text(widget.getLabel('[label]')),
      const SizedBox(width: 20),
      getText(100, false),
      Container(width: 20, height: 20, color: _color),
      const Spacer(),
      InkWell(
        onTap: _pickColor,
        child: const Icon(Icons.color_lens),
      )
    ]);

    return ret;
  }

  SizedBox getText(double width, bool border) {
    return SizedBox(
        width: width,
        child: TextField(
            decoration: InputDecoration(
                border: border ? const OutlineInputBorder() : InputBorder.none,
                isDense: true,
                contentPadding: border
                    ? const EdgeInsets.fromLTRB(5, 5, 5, 5)
                    : const EdgeInsets.fromLTRB(5, 0, 5, 0)),
            controller: edit));
  }

  void _pickBehaviour() async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const DesignerSelectorBehaviour(),
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
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
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
      IconData? ic = deserializeIcon(oneValue,  iconPack: IconPack.allMaterial,);
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
    IconData? icon = await showIconPicker(context,
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

    CWRepository? provider =
        CWApplication.of().loaderDesigner.factory.mapRepository[provID];

    var data = provider?.getQueryName() ?? 'no provider';
    return [
      SizedBox(
          height: CWForm.getHeightRow(widget) - 5,
          width: 200,
          child: TextFormField(
              readOnly: true,
              initialValue: data,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  labelText: 'Provider',
                  contentPadding: EdgeInsets.fromLTRB(5, 0, 5, 0))))
    , const Spacer(), const Icon(DBIcon.database, size: 20,)];
  }

  List<Widget> getSliderContent() {
    doubleValue = widget.getMapDouble();
    edit.text = doubleValue?.toInt().toString() ?? '';

    var slider = SizedBox(
        height: 10,
        width: 140,
        child: Slider(
          min: 0.0,
          max: 30.0,
          value: min(doubleValue ?? 0, 30),
          onChanged: (value) {
            setState(() {
              doubleValue = value;
              edit.text = value.toInt().toString();
            });
          },
        ));

    IconData? icon = widget.ctx.designEntity?.value['customValue']?['icon'];
    List<Widget> ret = [];
    if (icon != null) ret.addAll([Icon(icon), const SizedBox(width: 5)]);
    ret.addAll([
      Text(widget.getLabel('[label]')),
      const Spacer(),
      slider,
      getText(40, true)
    ]);
    return ret;
  }
}
