import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_factory.dart';
import 'package:xui_flutter/designer/designer.dart';

import '../core/data/core_provider.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/widget_selector.dart';

// ignore: must_be_immutable
class CWTextfield extends CWWidget {
  CWTextfield({
    super.key,
    required super.ctx,
  });

  @override
  State<CWTextfield> createState() => _CWTextfieldState();

  String getLabel() {
    return ctx.entityForFactory?.getString('label') ?? 'vide';
  }

  String getValue() {
    CWProvider? provider = ctx
        .factory.mapProvider[ctx.entityForFactory?.getString('providerName')];
    dynamic val =
        provider?.current.value[ctx.entityForFactory?.getString('bind')];
    return val?.toString() ?? "";
  }

  void setValue(String val) {
    String? providerName = ctx.entityForFactory?.getString('providerName');

    if (providerName != null) {
      final factory = CoreDesigner.loader.ctxLoader.factory;

      mapValue(val);

      String? xid = factory!.mapXidByPath[providerName];
      print('providerName $providerName xid = $xid');

      CWProvider? provider = ctx.factory.mapProvider[providerName];
      if (provider?.current.custom["onMap"] != null) {
        MapDesign map = provider?.current.custom["onMap"] as MapDesign;
        CWWidget? widget = factory.mapWidgetByXid[xid];
        widget?.ctx.entityForFactory = provider?.current;
        map.doMap(provider!.current);
      }

      // ignore: invalid_use_of_protected_member
      doRepaintByXid(factory, xid);
    }

    // ignore: prefer_interpolation_to_compose_strings
    print("object " + (ctx.entityForFactory?.toString() ?? ""));
  }

  void doRepaintByXid(WidgetFactoryEventHandler factory, String? xid) {
    CWWidget? widgetRepaint = factory.mapWidgetByXid[xid];
    // ignore: invalid_use_of_protected_member
    (widgetRepaint?.key as GlobalKey).currentState?.setState(() {});
  }

  void mapValue(String val) {
    dynamic v = val;
    String? providerName = ctx.entityForFactory?.getString('providerName');
    CWProvider? provider = ctx.factory.mapProvider[providerName];
    CoreDataAttribut? attr = provider?.current.getAttrByName(
        ctx.factory.collection, ctx.entityForFactory!.getString('bind')!);
    if (attr?.type == CDAttributType.CDint) {
      v = int.tryParse(val);
    }
    provider?.current.setAttr(
        ctx.factory.collection, ctx.entityForFactory!.getString('bind')!, v);
  }

  @override
  initSlot(String path) {}
}

class _CWTextfieldState extends State<CWTextfield> {
  final TextEditingController _controller = TextEditingController();
  String? last;

  @override
  void initState() {
    super.initState();
    last = widget.getValue();
    _controller.text = last!;
    _controller.addListener(() {
      //print('_controller $_controller');
      if (_controller.text != last) {
        widget.setValue(_controller.text);
        last = _controller.text;
      }

      // final String text = _controller.text.toLowerCase();
      // _controller.value = _controller.value.copyWith(
      //   text: text,
      //   selection:
      //       TextSelection(baseOffset: text.length, extentOffset: text.length),
      //   composing: TextRange.empty,
      // );
      //widget.ctx.entity!.setAttr(widget.ctx.factory.collection, "ok", _controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 32,
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 1.0, color: Theme.of(context).dividerColor))),
        child: TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.red, fontSize: 15),
          // keyboardType: TextInputType.number,
          scrollPadding: const EdgeInsets.all(0),
          inputFormatters: <TextInputFormatter>[
            // for below version 2 use this
            // FilteringTextInputFormatter.allow(
            //     RegExp(r'[0-9]')), //RegExp("[0-9]+.[0-9]")
            FilteringTextInputFormatter.singleLineFormatter,
            // LengthLimitingTextInputFormatter(12), //max length of 12 characters
          ],
          decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              labelText: widget.getLabel(),
              // labelStyle: const TextStyle(color: Colors.white70),
              contentPadding: const EdgeInsets.fromLTRB(5, 1, 5, 0)),
          autofocus: false,
        ));
  }
}
