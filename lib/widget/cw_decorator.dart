import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_slot.dart';
import '../designer/cw_factory.dart';

class CWDecorator extends CWWidget {
  const CWDecorator({super.key, required super.ctx});

  @override
  State<CWDecorator> createState() => _CWDecoratorState();

  @override
  void initSlot(String path) {
    addSlotPath('$path.Cont', SlotConfig('${ctx.xid}Cont'));
  }

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget('CWDecorator',
            (CWWidgetCtx ctx) => CWDecorator(key: ctx.getKey(), ctx: ctx))
        .addAttr('elevation', CDAttributType.int);
  }
}

class _CWDecoratorState extends StateCW<CWDecorator> {
  @override
  Widget build(BuildContext context) {
    return Card(
        margin: EdgeInsets.all(5),
        elevation: widget.getInt('elevation', null)?.toDouble(),
        child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: () {},
            child: Padding(
                padding: EdgeInsets.all(5.0),
                child: CWSlot(
                    type: 'body',
                    key: widget.ctx.getSlotKey('Cont', ''),
                    ctx: widget.createChildCtx(widget.ctx, 'Cont', null)))));
  }

  Widget getDecorator() {
    return Container(
      width: 200,
      height: 100,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(50)),
        boxShadow: [
          BoxShadow(
              color: Colors.amber, //New
              blurRadius: 25.0,
              offset: Offset(0, 25))
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(50)),
            color: Colors.red),
      ),
    );
  }
}
