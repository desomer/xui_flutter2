import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/data/core_data.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/cw_factory.dart';
import 'cw_list.dart';

class CWTextfield extends CWWidgetMap {
  const CWTextfield({
    super.key,
    required super.ctx,
  });

  @override
  State<CWTextfield> createState() => _CWTextfieldState();

  @override
  initSlot(String path) {}

  static initFactory(CWCollection c) {
    c
        .addWidget((CWTextfield),
            (CWWidgetCtx ctx) => CWTextfield(key: ctx.getKey(), ctx: ctx))
        .addAttr('label', CDAttributType.CDtext)
        .addAttr('withLabel', CDAttributType.CDbool)
        .withAction(AttrActionDefault(true))
        .addAttr('bind', CDAttributType.CDtext)
        .addAttr('providerName', CDAttributType.CDtext);
  }

  String? getLabelNull() {
    return (ctx.designEntity?.getBool("withLabel", true) ?? true)
        ? super.getLabel()
        : null;
  }
}

class _CWTextfieldState extends StateCW<CWTextfield> {
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();
  String? last;

  @override
  void initState() {
    super.initState();
    widget.initRow(context);
    last = widget.getValue();
    _controller.text = last!;
    _controller.addListener(() {
      //print('_controller $_controller');
      if (_controller.text != last) {
        widget.initRow(context);
        widget.setValue(_controller.text);
        last = _controller.text;
      }
    });
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    debugPrint("Focus: ${_focus.hasFocus.toString()} ${widget.ctx.pathWidget}");
    if (_focus.hasFocus) {
      InheritedStateContainer? row =
          context.getInheritedWidgetOfExactType<InheritedStateContainer>();

      if (row != null) {
        debugPrint("select row ${row.index}");
        row.selected(widget.ctx);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    widget.initRow(context);
    String? label = widget.getLabelNull();

    return Container(
        height: label == null ? 24 : 32,
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 1.0, color: Theme.of(context).dividerColor))),
        child: TextField(
          focusNode: _focus,
          controller: _controller,
          style: const TextStyle(/*color: Colors.red,*/ fontSize: 14),
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
              labelText: label,
              // labelStyle: const TextStyle(color: Colors.white70),
              contentPadding:
                  EdgeInsets.fromLTRB(5, label == null ? 7 : 1, 5, 0)),
          autofocus: true,
        ));
  }
}
