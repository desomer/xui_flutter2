import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/widget/cw_core_widget.dart';

// ignore: must_be_immutable
class CWTextfield extends CWWidget {
  CWTextfield({
    super.key,
    required super.ctx,
  });

  @override
  State<CWTextfield> createState() => _CWTextfieldState();

  String getLabel() {
    return ctx.entity?.getString('label', '') ?? 'vide';
  }

  @override
  initSlot(String path) {}
}

class _CWTextfieldState extends State<CWTextfield> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller.text = 'ok';

    _controller.addListener(() {
      print('_controller $_controller');
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
        decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(width: 1.0, color: Colors.black))),
        child: TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.red, fontSize: 15),
          keyboardType: TextInputType.number,
          scrollPadding: const EdgeInsets.all(0),
          inputFormatters: <TextInputFormatter>[
            // for below version 2 use this
            FilteringTextInputFormatter.allow(
                RegExp(r'[0-9]')), //RegExp("[0-9]+.[0-9]")
            FilteringTextInputFormatter.singleLineFormatter,
            LengthLimitingTextInputFormatter(12), //max length of 12 characters
          ],
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            labelText: widget.getLabel(),
            contentPadding: const EdgeInsets.fromLTRB(5, 1, 5, 0)
          ),
          autofocus: false,
        ));
  }
}
