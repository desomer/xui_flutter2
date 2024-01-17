import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:xui_flutter/widget/cw_array_row.dart';
import 'package:xui_flutter/widget/cw_array_cell.dart';
import '../core/data/core_data.dart';
import '../core/widget/cw_core_widget.dart';
import '../core/widget/cw_factory.dart';
import 'cw_container_form.dart';
import 'cw_list.dart';

class CWTextfield extends CWWidgetMapValue {
  const CWTextfield({
    super.key,
    required super.ctx,
  });

  @override
  State<CWTextfield> createState() => _CWTextfieldState();

  @override
  void initSlot(String path) {}

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget('CWTextfield',
            (CWWidgetCtx ctx) => CWTextfield(key: ctx.getKey(), ctx: ctx))
        .addAttr('bind', CDAttributType.one, tname: 'info')
        .addAttr('withLabel', CDAttributType.bool)
        .withAction(AttrActionDefault(true))
        .addAttr('label', CDAttributType.text)
        .addCustomValue('bindEnable', true)
        .addAttr('type', CDAttributType.text);
  }

  String? getLabelNull() {
    return (ctx.designEntity?.getBool('withLabel', true) ?? true)
        ? super.getLabel('[label]')
        : null;
  }

  String getType() {
    return ctx.designEntity?.getString('type', def: 'TEXT') ?? 'TEXT';
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
  bool isRowFocus = false;
  InheritedStateContainer? row;

  final TextEditingController _controller = TextEditingController();
  String? mapValue;
  String? lastOnFocus;
  GlobalKey? cellIndicatorKey;

  FocusNode findFocusNode() {
    if (row?.rowState != null) {
      isRowFocus = true;
      // recupére les focus de la row pour ne âs perdre le focus au repaint
      var f = row!.rowState!.mapFocus[widget.hashCode.toString()];
      if (f == null) {
        f = FocusNode();
        row!.rowState!.mapFocus[widget.hashCode.toString()] = f;
      } else {
        if (f.hasFocus) {
          // se repositionne aprés repaint
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
    row = widget.getRowState(context);
    _focus = findFocusNode();
    if (row != null) widget.setDisplayRow(row);

    // // map la valeur
    // var bind = widget.ctx.designEntity?.getOne('@bind');
    // mapValue = widget.getMapString(provInfo: bind);
    // _controller.text = mapValue!;

    _controller.addListener(_onTextChange);
    _focus.addListener(_onFocusChange);
  }

  void _onTextChange() {
    if (_controller.text != mapValue) {
      if (row != null) widget.setDisplayRow(row);
      bool valid = true;

      if (mask?.validator != null) {
        String? msg = mask?.validator!(_controller.text);
        valid = msg == null;
        if (mask!.error != msg) {
          mask!.error = msg;
          if (cellIndicatorKey != null) {
            CWCellIndicator indicator =
                cellIndicatorKey!.currentWidget as CWCellIndicator;
            indicator.color = valid ? null : Colors.red;
            indicator.message = msg;
            cellIndicatorKey!.currentState?.setState(() {});
          }
        }
      }
      var mode = widget.ctx.loader.mode;
      if (valid && mode == ModeRendering.view) {
        // map la valeur
        var bind = widget.ctx.designEntity?.getOne('@bind');
        widget.setValue(_controller.text, provInfo: bind);
        mapValue = _controller.text;
      }
    }
  }

  void _onFocusChange() {
    // debugPrint(
    //     "Focus: ${_focus.hasFocus.toString()} ${widget.ctx.pathWidget} ${_controller.text}");
    if (_focus.hasFocus) {
      //if (row != null) debugPrint("select row ${row.index}");
      row?.selected(widget.ctx);
      lastOnFocus = _controller.text;
      _controller.selectAll();
    } else {
      // repaint toute la ligne si perte de focus & changement
      if (lastOnFocus != _controller.text || mask?.error != null) {
        if (mask?.error != null) {
          _controller.text = lastOnFocus!;
        }
        row?.repaintRow(widget.ctx);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.removeListener(_onFocusChange);
    if (!isRowFocus) {
      _focus.dispose();
    }
    super.dispose();
  }

  MaskConfig? mask;
  static MaskTextInputFormatter maskDate = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {'#': RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.eager);

  @override
  Widget build(BuildContext context) {
    if (row != null) widget.setDisplayRow(row);

    String? label = widget.getLabelNull();
    String type = widget.getType();

    var bind = widget.ctx.designEntity?.getOne('@bind');
    mapValue = widget.getMapString(provInfo: bind);
    _controller.text = mapValue!;
    bool inArray = row != null;

    if (mask == null || mask?.type != type || mask?.label != label) {
      if (type == 'INTEGER' || type == 'INT') {
        mask = MaskConfig(
            inArray: inArray,
            ctx: widget.ctx,
            type: type,
            controller: _controller,
            focus: _focus,
            label: label,
            formatter: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
            textInputType: TextInputType.number);
      } else if (type == 'DOUBLE') {
        mask = MaskConfig(
            inArray: inArray,
            ctx: widget.ctx,
            type: type,
            controller: _controller,
            focus: _focus,
            label: label,
            formatter: [
              FilteringTextInputFormatter.allow(RegExp(r'(^-?\d*\.?\d*)'))
            ],
            textInputType: TextInputType.number);
      } else if (type == 'DATE') {
        mask = MaskConfig(
            inArray: inArray,
            ctx: widget.ctx,
            type: type,
            controller: _controller,
            focus: _focus,
            label: label,
            formatter: [maskDate],
            hint: '__/__/____',
            textInputType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return null;
              }
              final components = value.split('/');
              if (components.length == 3) {
                final day = int.tryParse(components[0]);
                final month = int.tryParse(components[1]);
                final year = int.tryParse(components[2]);
                if (day != null &&
                    month != null &&
                    year != null &&
                    year > 1900) {
                  var date = DateTime(year, month, day);
                  var bool = date.year == year &&
                      date.month == month &&
                      date.day == day;
                  if (bool) {
                    return null;
                  }
                }
              }
              return 'wrong date';
            });
      } else {
        // TEXT
        mask = MaskConfig(
            inArray: inArray,
            ctx: widget.ctx,
            type: type,
            controller: _controller,
            focus: _focus,
            label: label);
      }
    }

    return Container(
        height: inArray
            ? CWArrayRow.getHeightRow(widget)
            : CWForm.getHeightRow(widget),
        decoration: inArray
            ? null
            : BoxDecoration(
                // dans un formulaire
                border: Border(
                    bottom: BorderSide(
                        width: 0.5, color: Theme.of(context).dividerColor))),
        child: getCell(type));
  }

  Widget getCell(String type) {
    Widget content;
    if (type == 'DATE') {
      content = getDatePicker(mask!.getTextfield());
    } else {
      content = mask!.getTextfield();
    }

    if (row == null) {
      return content;
    } else {
      cellIndicatorKey ??= GlobalKey();
      // un indicateur à la fin
      return LayoutBuilder(
        builder: (context, constraints) {
          return Row(children: [
            SizedBox(
                width: constraints.maxWidth - 8,
                height: constraints.maxHeight,
                child: content),
            CWCellIndicator(key: cellIndicatorKey)
          ]);
        },
      );
    }
  }

  int pressCount = 0;

  Widget getDatePicker(Widget content) {
    return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (p) async {
          pressCount++;
          if (pressCount >= 2) {
            await openCalendar();
            pressCount = 0;
          } else {
            Timer(const Duration(milliseconds: 200), () {
              pressCount = 0;
            });
          }
        },
        child: content);
  }

  Future<void> openCalendar() async {
    String l = await findSystemLocale();
    List lsp = l.split('_');
    // ignore: use_build_context_synchronously
    DateTime? pickedDate = await showDatePicker(
        helpText: '',
        context: context,
        locale: Locale(lsp[0], lsp[1]),
        initialDate: _controller.text == ''
            ? DateTime.now()
            : DateFormat('dd/MM/yyyy').parse(_controller.text),
        firstDate: DateTime(1900),
        lastDate: DateTime(2101));

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);

      setState(() {
        _controller.text = formattedDate;
        row?.repaintRow(widget.ctx);
      });
    } else {
      debugPrint('Date is not selected');
    }
  }
}

class MaskConfig {
  final List<TextInputFormatter>? formatter;
  final FormFieldValidator<String>? validator;
  final String? hint;
  final TextInputType? textInputType;
  String? error;
  String? label;
  CWWidgetCtx? ctx;

  FocusNode focus;
  TextEditingController controller;
  String type;
  bool inArray;

  MaskConfig(
      {required this.controller,
      this.ctx,
      required this.inArray,
      required this.focus,
      this.formatter,
      this.validator,
      this.hint,
      this.label,
      this.textInputType,
      required this.type});

  TextField getTextfield() {
    var enable = (ctx?.loader.mode ?? ModeRendering.view) == ModeRendering.view;

    double topMargin = label == null ? (inArray ? 5 : 15) : 0;

    return TextField(
      //onTap: controller.selectAll,
      focusNode: focus,
      controller: controller,
      // style: const TextStyle(/*color: Colors.red,*/ fontSize: 14),
      keyboardType: textInputType,
      readOnly: !enable,
      enableInteractiveSelection: enable,
      // scrollPadding: const EdgeInsets.all(0),
      inputFormatters: formatter ?? [],
      autocorrect: false,
      decoration: InputDecoration(
          hintText: hint,
          errorText: error,
          border: InputBorder.none,
          isDense: true,
          labelText: label,
          // labelStyle: const TextStyle(color: Colors.white70),
          contentPadding: EdgeInsets.fromLTRB(5, topMargin, 5, 0)),
      //autofocus: true,
    );
  }
}
