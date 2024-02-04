import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/builder/prop_builder.dart';
import 'package:xui_flutter/designer/designer.dart';

const iDStyle = '_style_';

class CWStyledBoxConfig {
  AlignmentDirectional? align;
  EdgeInsets? margin;
  BoxDecoration? decoration;
  BorderRadius? borderRadius;
  BorderSide? side;
  EdgeInsets? padding;
  double hBorder = 0;
  double hPadding = 0;
  double hMargin = 0;

  double? height;
  double? width;

  void clear() {
    align = null;
    margin = null;
    decoration = null;
    borderRadius = null;
    side = null;
    padding = null;
    hBorder = 0;
    hPadding = 0;
    hMargin = 0;
    height = null;
    width = null;
  }
}

class CWStyledBox {
  CWStyledBox(this.widget) {
    style = widget.ctx.designEntity?.getOne(iDStyle);
  }

  final CWWidget widget;
  late Map<String, dynamic>? style;
  CWStyledBoxConfig config = CWStyledBoxConfig();

  bool styleExist(List<String> properties) {
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

  Widget getDragMargin(Widget w) {
    var mode = widget.ctx.modeRendering;
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

  void init() {
    style = widget.ctx.designEntity?.getOne(iDStyle);
    config.clear();
  }

  Widget getPaddingBox(Widget content) {
    if (config.padding != null) {
      return Padding(padding: config.padding!, child: content);
    }
    return content;
  }

  Widget getMarginBox(Widget content,
      {bool? withContainer, bool? withContentKey}) {
    init();
    if (style == null) {
      return getDragMargin(content);
    }

    widget.ctx.infoSelector.withPadding = false;
    setConfigMargin();

    if (withContainer ?? false) {
      setConfigBox();
      return getStyledContainer(content);
    } else {
      if (config.margin != null) {
        content = Padding(
            key: withContentKey ?? true ? widget.ctx.getContentKey(true) : null,
            padding: config.margin!,
            child: content);
      }
      return Container(alignment: config.align, child: getDragMargin(content));
    }
  }

  void setConfigMargin() {
    if (styleExist(['boxAlignVertical', 'boxAlignHorizontal'])) {
      config.align = AlignmentDirectional(
          double.parse(style!['boxAlignHorizontal'] ?? '-1'),
          double.parse(style!['boxAlignVertical'] ?? '-1'));
    }

    if (styleExist(['pleft', 'ptop', 'pright', 'pbottom'])) {
      var ptop = getStyleDouble('ptop', 0);
      var pbottom = getStyleDouble('pbottom', 0);
      config.margin = EdgeInsets.fromLTRB(getStyleDouble('pleft', 0), ptop,
          getStyleDouble('pright', 0), pbottom);
      config.hMargin = ptop + pbottom;
    }
  }

  void setConfigBox() {
    if (styleExist(['bSize', 'bColor'])) {
      var bSize = getStyleDouble('bSize', 1);
      config.side = BorderSide(
          width: bSize, color: getColor('bColor') ?? Colors.transparent);
      config.hBorder = bSize * 2;
    }

    if (styleExist(['bRadius'])) {
      config.borderRadius =
          BorderRadius.all(Radius.circular(getStyleDouble('bRadius', 0)));
    }

    if (config.side != null || styleExist(['bgColor', 'bRadius'])) {
      config.decoration = BoxDecoration(
        color: getColor('bgColor'),
        border:
            config.side != null ? Border.fromBorderSide(config.side!) : null,
        borderRadius: config.borderRadius,
      );
    }

    if (styleExist(['mleft', 'mtop', 'mright', 'mbottom'])) {
      var mtop = getStyleDouble('mtop', 0);
      var mbottom = getStyleDouble('mbottom', 0);
      config.padding = EdgeInsets.fromLTRB(getStyleDouble('mleft', 0), mtop,
          getStyleDouble('mright', 0), mbottom);
      config.hPadding = mtop + mbottom;
    }
  }

  Widget getClipRect(Widget content) {
    if (config.borderRadius != null) {
      return ClipRRect(borderRadius: config.borderRadius!, child: content);
    }
    return content;
  }

  RoundedRectangleBorder? getRoundedRectangleBorder() {
    if (config.borderRadius != null || config.side != null) {
      return RoundedRectangleBorder(
          borderRadius: getBorderRadius(),
          side: config.side ?? BorderSide.none);
    }
    return null;
  }

  BorderRadius getBorderRadius() {
    return config.borderRadius ?? const BorderRadius.all(Radius.circular(4.0));
  }

  Widget getStyledContainer(Widget content) {
    if (styleExist(['elevation'])) {
      content = Material(
          elevation: getElevation() ?? 0,
          borderRadius: config.borderRadius,
          child: getClipRect(Container(
              padding: config.padding,
              decoration: config.decoration,
              child: getDragMargin(content))));

      if (config.margin != null) {
        content = Padding(padding: config.margin!, child: content);
      }

      if (config.height != null || config.width != null) {
        content = SizedBox(
            height: config.height, width: config.width, child: content);
      }

      return content;
    } else if (config.margin != null ||
        config.decoration != null ||
        config.padding != null ||
        config.height != null ||
        config.width != null) {
      return Container(
          height: config.height,
          width: config.width,
          margin: config.margin,
          decoration: config.decoration,
          padding: config.padding,
          child: getClipRect(getDragMargin(content)));
    } else {
      return content;
    }
  }
}
