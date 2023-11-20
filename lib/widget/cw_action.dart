import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../designer/cw_factory.dart';

mixin CWActionManager {
  void doAction(CWWidget widget, Map<String, dynamic> properties) {
    CWWidgetEvent ctxWE = CWWidgetEvent();
    String? actionId = properties['_idAction_'];
    if (actionId==null) return;
    
    var p = actionId.split('@');
    ctxWE.action = p[0];
    CWProvider? provider = widget.ctx.loader.factory.mapProvider[p[1]];
    if (provider != null) {
      ctxWE.provider = provider;
      ctxWE.loader = widget.ctx.loader;
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

  Map<String, dynamic>? getIcon() {
    return ctx.designEntity?.value['icon'];
  }
}

class _CWActionLinkState extends StateCW<CWActionLink> {
  @override
  Widget build(BuildContext context) {
    SlotConfig? slotConfig =
        widget.ctx.factory.mapSlotConstraintByPath[widget.ctx.pathWidget];
    String type = slotConfig?.slot?.type ?? '';

    if (type == 'navigation') {
      return getNavBtn();
    }

    if (type == 'title') {
      return InkWell(onTap: () {
          widget.doAction(widget, widget.ctx.designEntity!.value);
      }, child: Text(widget.getLabel()));
    }

    return ElevatedButton(
      child: Text(widget.getLabel()),
      onPressed: () {},
    );
  }

  Widget getNavBtn() {
    Map<String, dynamic>? v = widget.getIcon();
    Widget icon = Container();
    if (v != null) {
      IconData? ic = deserializeIcon(v);
      icon = Icon(ic);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        icon, // <-- Icon
        Text(widget.getLabel(),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: IconTheme.of(context).color,
                )), // <-- Text
      ],
    );
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
