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
  void initSlot(String path, ModeParseSlot mode) {}

  static void initFactory(CWWidgetCollectionBuilder c) {
    List visualStyle = [
      {'icon': Icons.tablet_outlined, 'value': 'border'},
      {'icon': Icons.rectangle_rounded, 'value': 'fill'},
      {'icon': Icons.horizontal_rule, 'value': 'under'},
      {'icon': Icons.format_list_bulleted, 'value': 'list'},
    ];

    c
        .addWidget('CWTextfield',
            (CWWidgetCtx ctx) => CWTextfield(key: ctx.getKey(), ctx: ctx))
        .addAttr('bind', CDAttributType.one, tname: 'info')
        .addCustomValue('bindEnable', true)
        .addAttr('withLabel', CDAttributType.bool)
        .withAction(AttrActionDefault(true))
        .addAttr('label', CDAttributType.text)
        .addCustomValue('bindEnable', true)
        .addAttr('vstyle', CDAttributType.text, tname: 'toogle')
        .addCustomValue('bindValue', visualStyle)
        .addAttr('_type_', CDAttributType.text);
  }

  String? getLabelNull() {
    return (ctx.designEntity?.getBool('withLabel', true) ?? true)
        ? super.getLabel('[label]')
        : null;
  }

  String getBindType() {
    return ctx.designEntity?.getString('_type_', def: 'TEXT') ?? 'TEXT';
  }

  String getVisualStyle() {
    return ctx.designEntity?.getString('vstyle', def: 'border') ?? 'border';
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
  InheritedRow? row;

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
    if (row != null) widget.setRepositoryDisplayRow(row);

    // // map la valeur
    // var bind = widget.ctx.designEntity?.getOne('@bind');
    // mapValue = widget.getMapString(provInfo: bind);
    // _controller.text = mapValue!;

    _controller.addListener(_onTextChange);
    _focus.addListener(_onFocusChange);
  }

  void _onTextChange() {
    if (_controller.text != mapValue) {
      if (row != null) widget.setRepositoryDisplayRow(row);
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
        widget.setValue(_controller.text, provInfo: bind, row: row);
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

        var bind = widget.ctx.designEntity?.getOne('@bind');
        widget.doValidateEntity(row: row, provInfo: bind);

        //row?.repaintRow(widget.ctx);
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
    if (row != null) widget.setRepositoryDisplayRow(row);

    String? label = widget.getLabelNull();
    String type = widget.getBindType();
    String visualType = widget.getVisualStyle();

    var bind = widget.ctx.designEntity?.getOne('@bind');
    mapValue = widget.getMapString(provInfo: bind);
    _controller.text = mapValue!;
    bool inArray = row != null;

    initMask(visualType, type, label, inArray);

    styledBox.init();
    styledBox.setConfigBox();
    styledBox.setConfigMargin();
    styledBox.config.height =
        inArray ? CWArrayRow.getHeightRow(widget) : CWForm.getHeightRow(widget);

    bool withUnderline = visualType == 'list';

    styledBox.config.decoration ??= inArray || !withUnderline
        ? null
        : BoxDecoration(
            // dans un formulaire
            border: Border(
                bottom: BorderSide(
                    width: 0.5, color: Theme.of(context).dividerColor)));

    return styledBox.getStyledContainer(getCell(type));
  }

  void initMask(
      String visualType, String bindType, String? label, bool inArray) {
    var maskChanged = mask == null ||
        mask?.bindType != bindType ||
        mask?.label != label ||
        mask?.visualType != visualType;

    if (maskChanged) {
      if (bindType == 'INTEGER' || bindType == 'INT') {
        mask = MaskConfig(
            inArray: inArray,
            ctx: widget.ctx,
            bindType: 'INT',
            visualType: visualType,
            controller: _controller,
            focus: _focus,
            label: label,
            formatter: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
            textInputType: TextInputType.number);
      } else if (bindType == 'DOUBLE' || bindType == 'DEC') {
        mask = MaskConfig(
            inArray: inArray,
            ctx: widget.ctx,
            bindType: 'DOUBLE',
            visualType: visualType,
            controller: _controller,
            focus: _focus,
            label: label,
            formatter: [
              FilteringTextInputFormatter.allow(RegExp(r'(^-?\d*\.?\d*)'))
            ],
            textInputType: TextInputType.number);
      } else if (bindType == 'DATE') {
        mask = MaskConfig(
            inArray: inArray,
            ctx: widget.ctx,
            bindType: bindType,
            visualType: visualType,
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
            bindType: bindType,
            visualType: visualType,
            controller: _controller,
            focus: _focus,
            label: label);
      }
    }
  }

  Widget getCell(String bindType) {
    Widget content;
    if (bindType == 'DATE') {
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
    DateTime? pickedDate = await showDatePicker(
        helpText: '',
        // ignore: use_build_context_synchronously
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
        var bind = widget.ctx.designEntity?.getOne('@bind');
        widget.doValidateEntity(row: row, provInfo: bind);
        //row?.repaintRow(widget.ctx);
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
  String bindType;
  String visualType;
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
      required this.bindType,
      required this.visualType});

  TextField getTextfield() {
    var enable = (ctx?.loader.mode ?? ModeRendering.view) == ModeRendering.view;

    double topMargin = label == null ? (inArray ? 5 : 15) : 0;
    bool isNum = bindType == 'INT' || bindType == 'DOUBLE';

    InputDecoration? inputDecoration;
    if (visualType == 'list') {
      inputDecoration = InputDecoration(
          hintText: hint,
          errorText: error,
          labelText: label,
          border: InputBorder.none,
          isDense: true,
          // labelStyle: const TextStyle(color: Colors.white70),
          contentPadding: EdgeInsets.fromLTRB(5, topMargin, 5, 0));
    } else if (visualType == 'border') {
      inputDecoration = InputDecoration(
        hintText: hint,
        errorText: error,
        labelText: label,
        // prefixIcon: Icon(Icons.search),
        // suffixIcon: Icon(Icons.clear),
        border: const OutlineInputBorder(),
      );
    } else if (visualType == 'fill') {
      inputDecoration = InputDecoration(
        hintText: hint,
        errorText: error,
        labelText: label,
        filled: true,
        // prefixIcon: Icon(Icons.search),
        // suffixIcon: Icon(Icons.clear),
        // border: const OutlineInputBorder(),
      );
    } else {
      inputDecoration = const InputDecoration();
    }
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
      textAlign: isNum ? TextAlign.right : TextAlign.start,
      decoration: inputDecoration,
      //autofocus: true,
    );
  }
}
