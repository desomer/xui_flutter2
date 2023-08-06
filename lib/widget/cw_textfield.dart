import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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
        .addAttr('providerName', CDAttributType.CDtext)
        .addAttr('type', CDAttributType.CDtext)
        .addAttr('mask', CDAttributType.CDtext);
  }

  String? getLabelNull() {
    return (ctx.designEntity?.getBool("withLabel", true) ?? true)
        ? super.getLabel()
        : null;
  }

  String getType() {
    return ctx.designEntity?.getString("type", def: "TEXT") ?? "TEXT";
  }
}

extension TextEditingControllerExt on TextEditingController {
  void selectAll() {
    if (text.isEmpty) return;
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }
}

class _CWTextfieldState extends StateCW<CWTextfield> {
  late FocusNode _focus;
  final TextEditingController _controller = TextEditingController();
  String? last;
  String? lastOnFocus;

  FocusNode initFocusNode() {
    InheritedStateContainer? row =
        context.getInheritedWidgetOfExactType<InheritedStateContainer>();
    if (row != null && row.rowState != null) {
      var f = row.rowState!.mapFocus[widget.hashCode.toString()];
      if (f == null) {
        f = FocusNode();
        row.rowState!.mapFocus[widget.hashCode.toString()] = f;
      } else {
        if (f.hasFocus) {
          f.unfocus();
          Future.delayed(const Duration(milliseconds: 100), () {
            f!.requestFocus();
          });
        }
      }
      return f;
    }

    return FocusNode();
  }

  @override
  void initState() {
    super.initState();
    _focus = initFocusNode();
    widget.initRow(context);
    last = widget.getMapValue();
    _controller.text = last!;
    _controller.addListener(() {
      if (_controller.text != last) {
        widget.initRow(context);
        bool valid = true;
        if (mask?.validator != null) {
          String? msg = mask?.validator!(_controller.text);
          valid = msg == null;
          if (mask!.error != msg) {
            // setState(() {
            mask!.error = msg;
            // });
          }
        }
        if (valid) {
          widget.setValue(_controller.text);
        }
        last = _controller.text;
      }
    });
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    debugPrint(
        "Focus: ${_focus.hasFocus.toString()} ${widget.ctx.pathWidget} ${_controller.text}");
    if (_focus.hasFocus) {
      InheritedStateContainer? row =
          context.getInheritedWidgetOfExactType<InheritedStateContainer>();
      if (row != null) {
        // debugPrint("select row ${row.index}");
        row.selected(widget.ctx);
      }
      lastOnFocus = _controller.text;
      _controller.selectAll();
    } else {
      //_focus.requestFocus();
      // repaint toute la ligne si changement
      if (lastOnFocus != _controller.text || mask?.error != null) {
        if (mask?.error != null) {
          _controller.text = lastOnFocus!;
        }
        context
            .getInheritedWidgetOfExactType<InheritedStateContainer>()
            ?.repaintRow(widget.ctx);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.removeListener(_onFocusChange);
//    _focus.dispose();
    super.dispose();
  }

  MaskConfig? mask;

  @override
  Widget build(BuildContext context) {
    widget.initRow(context);
    String? label = widget.getLabelNull();
    String type = widget.getType();
    // var formater = <TextInputFormatter>[
    //   // // for below version 2 use this
    //   // FilteringTextInputFormatter.allow(
    //   //     RegExp(r'[0-9]')), //RegExp("[0-9]+.[0-9]")
    //   // FilteringTextInputFormatter.singleLineFormatter,
    //   // // LengthLimitingTextInputFormatter(12), //max length of 12 characters
    // ];

    if (type == "INTEGER") {
      mask = MaskConfig(
          formatter: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
          textInputType: TextInputType.number);
    }
    if (type == "DOUBLE") {
      mask = MaskConfig(formatter: [
        FilteringTextInputFormatter.allow(RegExp(r'(^-?\d*\.?\d*)'))
      ], textInputType: TextInputType.number);
    }

    if (type == "DATE") {
      var maskFormatter = MaskTextInputFormatter(
          mask: '##/##/####',
          filter: {"#": RegExp(r'[0-9]')},
          type: MaskAutoCompletionType.lazy);

      mask = MaskConfig(
          formatter: [maskFormatter],
          hint: "01/12/2023",
          textInputType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return null;
            }
            final components = value.split("/");
            if (components.length == 3) {
              final day = int.tryParse(components[0]);
              final month = int.tryParse(components[1]);
              final year = int.tryParse(components[2]);
              if (day != null && month != null && year != null && year > 1900) {
                var date = DateTime(year, month, day);
                var bool =
                    date.year == year && date.month == month && date.day == day;
                if (bool) {
                  return null;
                }
              }
            }
            return "wrong date";
          });
    }

    return Container(
        height: label == null ? 24 : 32,
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 1.0, color: Theme.of(context).dividerColor))),
        child: GestureDetector(
            onDoubleTap: () async {
              if (kIsWeb) {}
              String l = await findSystemLocale();
              List lsp = l.split("_");
              // ignore: use_build_context_synchronously
              DateTime? pickedDate = await showDatePicker(
                  helpText: "",
                  context: context,
                  locale: Locale(lsp[0], lsp[1]),
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2101));

              if (pickedDate != null) {
                String formattedDate =
                    DateFormat('dd/MM/yyyy').format(pickedDate);

                setState(() {
                  _controller.text = formattedDate;
                });
              } else {
                print("Date is not selected");
              }
            },
            child: TextField(
              // onTapOutside: (e) {
              //   print("onTapOutside");
              // },
              onTap: _controller.selectAll,
              focusNode: _focus,
              controller: _controller,
              style: const TextStyle(/*color: Colors.red,*/ fontSize: 14),
              keyboardType: mask?.textInputType,
              scrollPadding: const EdgeInsets.all(0),
              inputFormatters: mask?.formatter ?? [],
              autocorrect: false,
              decoration: InputDecoration(
                  hintText: mask?.hint,
                  errorText: mask?.error,
                  border: InputBorder.none,
                  isDense: true,
                  labelText: label,
                  // labelStyle: const TextStyle(color: Colors.white70),
                  contentPadding:
                      EdgeInsets.fromLTRB(5, label == null ? 7 : 1, 5, 0)),
              //autofocus: true,
            )));
  }
}

class MaskConfig {
  final List<TextInputFormatter>? formatter;
  final FormFieldValidator<String>? validator;
  final String? hint;
  final TextInputType textInputType;
  String? error;

  MaskConfig(
      {required this.formatter,
      this.validator,
      this.hint,
      required this.textInputType});
}
