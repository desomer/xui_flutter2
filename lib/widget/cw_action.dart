import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

import '../core/data/core_data.dart';
import '../core/data/core_repository.dart';
import '../core/widget/cw_core_drag.dart';
import '../core/widget/cw_core_widget.dart';
import '../core/widget/cw_factory.dart';
import '../designer/action_manager.dart';
import '../designer/application_manager.dart';
import '../designer/designer.dart';
import 'cw_list.dart';

mixin CWActionManager {
  bool hasAction(CWWidget widget) {
    return widget.ctx.designEntity?.value['_idAction_'] != null ? true : false;
  }

  void doAction(BuildContext? context, CWWidget widget,
      Map<String, dynamic>? properties) {
    var mode = widget.ctx.loader.mode;
    if (mode == ModeRendering.design && !widget.ctx.isSelectedSince(200)) {
      return;
    }
    if (CoreDesigner.of().isShiftPress()) {
      return;
    }

    CWWidgetEvent ctxWE = CWWidgetEvent();
    if (properties == null) return;
    String? actionId = properties['_idAction_'];
    if (actionId == null) return;

    var p = actionId.split('@');
    ctxWE.action = p[0];
    String dest = p[1];
    if (dest == 'router') {
      CWApplication.of().goRoute(p[0]);
    } else {
      CWRepository? provider = widget.ctx.loader.factory.mapRepository[dest];
      if (provider != null) {
        ctxWE.provider = provider;
        ctxWE.loader = widget.ctx.loader;
        ctxWE.buildContext = context;
        provider.doUserAction(widget.ctx, ctxWE, ctxWE.action!);
      } else {
        print('provider $dest inconnu');
      }
    }
  }
}

class CWActionLink extends CWWidget with CWActionManager, CWWidgetInheritRow {
  const CWActionLink({super.key, required super.ctx});

  @override
  State<CWActionLink> createState() => _CWActionLinkState();

  @override
  void initSlot(String path, ModeParseSlot mode) {}

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget('CWActionLink',
            (CWWidgetCtx ctx) => CWActionLink(key: ctx.getKey(), ctx: ctx))
        .addAttr('label', CDAttributType.text)
        .addAttr('icon', CDAttributType.one, tname: 'icon')
        .addAttr('_idAction_', CDAttributType.text);
  }
}

class _CWActionLinkState extends StateCW<CWActionLink> with CWDroppableEvent {
  InheritedRow? row;

  @override
  void initState() {
    super.initState();
    row = widget.getRowState(context);
  }

  @override
  Widget build(BuildContext context) {
    if (row != null) widget.setRepositoryDisplayRow(row);

    SlotConfig? slotConfig =
        widget.ctx.factory.mapSlotConstraintByPath[widget.ctx.pathWidget];
    String type = slotConfig?.slot?.type ?? '';

    return styledBox.getMarginBox(
        getDropZoneEvent(widget.ctx, indicatorEvent(getBtn(type, context))));
  }

  Widget indicatorEvent(Widget child) {
    if (widget.ctx.modeRendering == ModeRendering.view ||
        !widget.hasAction(widget)) {
      return child;
    }

    return Stack(fit: StackFit.passthrough, children: [
      child,
      const Positioned(
          top: 0,
          right: 0,
          child: Icon(size: 15, color: Colors.deepOrangeAccent, Icons.bolt))
    ]);
  }

  Widget getBtn(String type, BuildContext context) {
    if (type == 'appbar') {
      return getIconBtn();
    } else if (type == 'navigation') {
      return getNavBtn();
    } else if (type == 'title') {
      // label de expand panel
      return InkWell(
          onTap: () {
            doAction();
          },
          child: Text(widget.getLabel('[label]')));
    } else {
      return getElevatedBtn(context);
    }
  }

  void doAction() {
    if (row != null) {
      row!.selected(widget.ctx);
    }
    if (widget.ctx.designEntity != null) {
      widget.doAction(context, widget, widget.ctx.designEntity!.value);
    }
  }

  ElevatedButton getElevatedBtn(BuildContext context) {
    Widget? icon = getIcon();

    ButtonStyle? style;
    BorderSide? side;
    OutlinedBorder? border;
    styledBox.init();
    styledBox.setConfigBox();

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

    if (styledBox.config.padding != null ||
        styledBox.styleExist(['elevation', 'bgColor'])) {
      style = ElevatedButton.styleFrom(
          shape: border,
          padding: styledBox.config.padding,
          elevation: styledBox.getElevation(),
          backgroundColor: styledBox.getColor('bgColor'));
    }

    String? label = widget.getLabelOrNull(null);

    if (icon != null) {
      if (label != null) {
        return ElevatedButton.icon(
            key: widget.ctx.getContentKey(false),
            style: style,
            onPressed: () {
              doAction();
            },
            icon: icon,
            label: Text(label));
      } else {
        return ElevatedButton(
            key: widget.ctx.getContentKey(false),
            style: style,
            onPressed: () {
              doAction();
            },
            child: FittedBox(fit: BoxFit.fitWidth, child: icon));
      }
    } else {
      return ElevatedButton(
        key: widget.ctx.getContentKey(false),
        style: style,
        onPressed: () {
          doAction();
        },
        child: Text(widget.getLabel('[label]')),
      );
    }
  }

  Widget getIconBtn() {
    Widget? icon = getIcon();
    return IconButton(
      icon: icon ?? const Icon(Icons.abc),
      onPressed: () {
        doAction();
      },
    );
  }

  Widget getNavBtn() {
    Widget? icon = getIcon();
    String? label = widget.getLabelOrNull(icon == null ? '[label]' : null);

    var childNav = <Widget>[];
    if (icon != null) childNav.add(icon);
    if (label != null) {
      childNav.add(Text(label,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: IconTheme.of(context).color,
              )));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: childNav,
    );
  }

  Widget? getIcon() {
    Map<String, dynamic>? v = widget.getIcon();
    Widget? icon;
    if (v != null) {
      IconData? ic = deserializeIcon(
        v,
        iconPack: IconPack.allMaterial,
      );
      icon = Icon(ic);
    }
    return icon;
  }

  @override
  void onDragEvent(DragEventCtx query) {
    if (query is DragPageCtx && query.page.type == 'PageModel') {
      DesignActionManager().doPageAction(widget.ctx, query);
      setState(() {});
    }
    if (query is DragRepositoryEventCtx) {
      DesignActionManager().doReposAction(widget.ctx, query);
      setState(() {});
    }

    // SlotConfig? slotConfig =
    //     widget.ctx.factory.mapSlotConstraintByPath[widget.ctx.pathWidget];
    // String type = slotConfig?.slot?.type ?? '';

    // print(query);
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
