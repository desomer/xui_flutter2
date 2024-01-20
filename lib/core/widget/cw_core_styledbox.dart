import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/builder/prop_builder.dart';
import 'package:xui_flutter/designer/designer.dart';

const iDStyle = '_style_';

class CWStyledBox {
  CWStyledBox(this.widget) {
    style = widget.ctx.designEntity?.getOne(iDStyle);
  }

  final CWWidget widget;
  late Map<String, dynamic>? style;

  bool styleExist(List<String> properties) {
    style = widget.ctx.designEntity?.getOne(iDStyle);
    for (var p in properties) {
      if (style?[p] != null) {
        return true;
      }
    }
    return false;
  }

  double getStyleDouble(String id, double def) {
    return style?[id] ?? def;
  }

  double? getStyleNDouble(String id) {
    return style?[id];
  }

  double? getElevation() {
    return getStyleNDouble('elevation');
  }

  Color? getColor(String id) {
    var oneValue = style?[id];
    return oneValue != null
        ? Color(int.parse(oneValue['color'], radix: 16))
        : null;
  }

  // Offset dragAnchorStrategy(
  //     Draggable<Object> d, BuildContext context, Offset point) {
  //   return Offset(d.feedbackOffset.dx + 10, d.feedbackOffset.dy + 10);
  // }

  Widget getDragPadding(Widget w) {
    var mode = widget.ctx.loader.mode;
    if (mode == ModeRendering.view || !CoreDesigner.of().isAltPress()) {
      return w;
    }

    return Draggable<String>(
      onDragUpdate: (details) {
        CoreDataEntity prop = PropBuilder.preparePropChange(
            widget.ctx.loader, DesignCtx().forDesign(widget.ctx));

        Map<String, dynamic>? s = prop.value[iDStyle];
        if (s == null) {
          prop.value[iDStyle] = widget.ctx.factory.loader.collectionDataModel
              .createEntity('StyleModel')
              .value;
        }
        doMoveAxe(s, 'boxAlignHorizontal', 'pleft', 'pright', details.delta.dx);
        doMoveAxe(s, 'boxAlignVertical', 'ptop', 'pbottom', details.delta.dy);

        widget.repaint();
        CoreDesigner.emit(CDDesignEvent.reselect, null);
      },
      //dragAnchorStrategy: dragAnchorStrategy,
      data: 'drag',
      feedback: Container(),
      child: w,
    );
  }

  void doMoveAxe(
      Map<String, dynamic>? s, String axe, String a, String b, double delta) {
    var align = s?[axe] ?? '-1';
    if (align == '-1' || align == '0') {
      double v = s?[a] ?? 0;
      s?[a] = max(0.0, v + delta);
      s?.remove(b);
    } else {
      double v = s?[b] ?? 0;
      s?[b] = max(0.0, v - delta);
      s?.remove(a);
    }
  }

  Widget getStyledBox(Widget content) {
    if (style == null) {
      return getDragPadding(content);
    }
    AlignmentDirectional? align;
    if (styleExist(['boxAlignVertical', 'boxAlignHorizontal'])) {
      align = AlignmentDirectional(
          double.parse(style!['boxAlignHorizontal'] ?? '-1'),
          double.parse(style!['boxAlignVertical'] ?? '-1'));
    }

    widget.ctx.infoSelector.withPadding = false;
    if (styleExist(['pleft', 'ptop', 'pright', 'pbottom'])) {
      EdgeInsets padding = EdgeInsets.fromLTRB(
          getStyleDouble('pleft', 0),
          getStyleDouble('ptop', 0),
          getStyleDouble('pright', 0),
          getStyleDouble('pbottom', 0));
      content = Padding(
          key: widget.ctx.getContentKey(true),
          padding: padding,
          child: content);
    }

    return Container(alignment: align, child: getDragPadding(content));
  }
}
