import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/widget/cw_core_slot.dart';
import '../core/widget/cw_factory.dart';

class CWCard extends CWWidget {
  const CWCard({super.key, required super.ctx});

  @override
  State<CWCard> createState() => _CWCardState();

  @override
  void initSlot(String path, ModeParseSlot mode) {
    addSlotPath('$path.Cont', SlotConfig(XidBuilder(tag:'Cont'), ctx.xid), mode);
  }

  static void initFactory(CWWidgetCollectionBuilder c) {
    c.addWidget(
        'CWCard', (CWWidgetCtx ctx) => CWCard(key: ctx.getKey(), ctx: ctx));
  }
}

class _CWCardState extends StateCW<CWCard> {
  @override
  Widget build(BuildContext context) {
    styledBox.init();
    styledBox.setConfigBox();

    return styledBox.getMarginBox(withContentKey: false, Card(
        key: widget.ctx.getContentKey(true), 
        shape: styledBox.getRoundedRectangleBorder(),
        elevation: styledBox.getElevation(),
        //  margin: styledBox.config.margin,
        color: styledBox.config.decoration?.color,
        child: InkWell(
            borderRadius: styledBox.getBorderRadius(),
            //onTap: () {},
            child: styledBox.getPaddingBox(CWSlot(
                type: 'body',
                key: widget.ctx.getSlotKey('Cont', ''),
                ctx: widget.createChildCtx(widget.ctx, 'Cont', null))))));
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
