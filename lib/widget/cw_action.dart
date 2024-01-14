import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../designer/cw_factory.dart';

mixin CWActionManager {
  void doAction(
      BuildContext context, CWWidget widget, Map<String, dynamic>? properties) {
    CWWidgetEvent ctxWE = CWWidgetEvent();
    if (properties == null) return;
    String? actionId = properties['_idAction_'];
    if (actionId == null) return;

    var p = actionId.split('@');
    ctxWE.action = p[0];
    String dest = p[1];
    CWProvider? provider = widget.ctx.loader.factory.mapProvider[dest];
    if (provider != null) {
      ctxWE.provider = provider;
      ctxWE.loader = widget.ctx.loader;
      ctxWE.buildContext = context;
      provider.doUserAction(widget.ctx, ctxWE, ctxWE.action!);
    }
  }
}

class CWActionLink extends CWWidget with CWActionManager {
  const CWActionLink({super.key, required super.ctx});

  @override
  State<CWActionLink> createState() => _CWActionLinkState();

  @override
  void initSlot(String path) {}

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget('CWActionLink',
            (CWWidgetCtx ctx) => CWActionLink(key: ctx.getKey(), ctx: ctx))
        .addAttr('label', CDAttributType.text)
        .addAttr('icon', CDAttributType.one, tname: 'icon')
        .addAttr('_idAction_', CDAttributType.text);
  }
}

class _CWActionLinkState extends StateCW<CWActionLink> {
  @override
  Widget build(BuildContext context) {
    SlotConfig? slotConfig =
        widget.ctx.factory.mapSlotConstraintByPath[widget.ctx.pathWidget];
    String type = slotConfig?.slot?.type ?? '';
    return styledBox.getStyledBox(getBtn(type, context));
  }

  Widget getBtn(String type, BuildContext context) {
    if (type == 'appbar') {
      return getIconBtn();
    } else if (type == 'navigation') {
      return getNavBtn();
    } else if (type == 'title') {
      return InkWell(
          onTap: () {
            widget.doAction(context, widget, widget.ctx.designEntity!.value);
          },
          child: Text(widget.getLabel('[label]')));
    } else {
      Widget? icon = getIcon();

      ButtonStyle? style;
      BorderSide? side;
      OutlinedBorder? border;

      if (styledBox.styleExist(['bSize', 'bColor'])) {
        side = BorderSide(
            width: styledBox.getStyleDouble('bSize', 1),
            color: styledBox.getColor('bColor') ?? Colors.transparent);
      }
      if (styledBox.styleExist(['bRadius'])) {
        border = RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
                Radius.circular(styledBox.getStyleDouble('bRadius', 0))),
            side: side ?? BorderSide.none);
      } else if (side != null) {
        border = StadiumBorder(side: side);
      }

      if (styledBox.styleExist(['elevation', 'bgColor'])) {
        style = ElevatedButton.styleFrom(
            shape: border,
            elevation: styledBox.getElevation(),
            backgroundColor: styledBox.getColor('bgColor'));
      }

      if (icon != null) {
        return ElevatedButton.icon(
            key: widget.ctx.getContentKey(false),
            style: style,
            onPressed: () {
              widget.doAction(context, widget, widget.ctx.designEntity?.value);
            },
            icon: icon,
            label: Text(widget.getLabel('[label]')));
      } else {
        return ElevatedButton(
          key: widget.ctx.getContentKey(false),
          style: style,
          onPressed: () {
            widget.doAction(context, widget, widget.ctx.designEntity?.value);
          },
          child: Text(widget.getLabel('[label]')),
        );
      }
    }
  }

  Widget getIconBtn() {
    Widget? icon = getIcon();
    return IconButton(
      icon: icon ?? const Icon(Icons.abc),
      onPressed: () {
        widget.doAction(context, widget, widget.ctx.designEntity?.value);
      },
    );
  }

  Widget getNavBtn() {
    Widget? icon = getIcon();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        icon ?? Container(), // <-- Icon
        Text(widget.getLabel('[label]'),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: IconTheme.of(context).color,
                )),
      ],
    );
  }

  Widget? getIcon() {
    Map<String, dynamic>? v = widget.getIcon();
    Widget? icon;
    if (v != null) {
      IconData? ic = deserializeIcon(v);
      icon = Icon(ic);
    }
    return icon;
  }

  // Widget getOvalBtn() {
  //   return SizedBox.fromSize(
  //     size: const Size(56, 56),
  //     child: ClipOval(
  //       child: Material(
  //         color: Colors.amberAccent,
  //         child: InkWell(
  //           splashColor: Colors.green,
  //           onTap: () {},
  //           child: const Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: <Widget>[
  //               Icon(Icons.shopping_cart), // <-- Icon
  //               Text('Buy'), // <-- Text
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
