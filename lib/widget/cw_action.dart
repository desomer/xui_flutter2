import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../designer/cw_factory.dart';

class CWAction extends CWWidget {
  const CWAction({super.key, required super.ctx});

  @override
  State<CWAction> createState() => _CWActionState();

  @override
  void initSlot(String path) {}

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget('CWAction',
            (CWWidgetCtx ctx) => CWAction(key: ctx.getKey(), ctx: ctx))
        .addAttr('label', CDAttributType.text)
        .addAttr('textColor', CDAttributType.text);
  }

  String getLabel() {
    return ctx.designEntity?.getString('label') ?? '[empty]';
  }
}

class _CWActionState extends StateCW<CWAction> {
  @override
  Widget build(BuildContext context) {
    SlotConfig? slotConfig =
        widget.ctx.factory.mapSlotConstraintByPath[widget.ctx.pathWidget];
    String type = slotConfig?.slot?.type ?? '';

    if (type == 'navigation') {
      return getNavBtn();
    }

    return ElevatedButton(
      child: Text(widget.getLabel()),
      onPressed: () {},
    );
  }

  Widget getNavBtn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(Icons.shopping_cart), // <-- Icon
        Text(widget.getLabel(), style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: IconTheme.of(context).color,
        )), // <-- Text
      ],
    );
  }

  Widget getOvalBtn() {
    return SizedBox.fromSize(
      size: const Size(56, 56),
      child: ClipOval(
        child: Material(
          color: Colors.amberAccent,
          child: InkWell(
            splashColor: Colors.green,
            onTap: () {},
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.shopping_cart), // <-- Icon
                Text('Buy'), // <-- Text
              ],
            ),
          ),
        ),
      ),
    );
  }
}
