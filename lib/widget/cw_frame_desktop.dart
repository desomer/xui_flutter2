import 'package:flutter/material.dart';

import '../core/widget/cw_core_slot.dart';
import '../core/widget/cw_core_widget.dart';

class CWFrameDesktop extends CWWidget {
  CWFrameDesktop({super.key, required super.ctx});

  final keySlot = GlobalKey(debugLabel: "slot main");

  @override
  State<CWFrameDesktop> createState() => _CWFrameDesktop();

  @override
  initSlot(String path) {
    addSlotPath('root', SlotConfig('root'));
    addSlotPath('$path.Body', SlotConfig('${ctx.xid}Body'));
  }
}

class _CWFrameDesktop extends StateCW<CWFrameDesktop> {
  @override
  Widget build(BuildContext context) {
    return CWSlot(
        key: widget.keySlot,
        ctx: widget.ctx,
        childForced: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Mouse Region',
            home: Scaffold(
              appBar: AppBar(
                title: Text(
                    widget.ctx.designEntity!.getString('title', def: '?')!),
              ),
              body: Column(children: [
                Expanded(
                    child: CWSlot(
                        key: GlobalKey(debugLabel: "slot body"),
                        ctx: widget.createChildCtx('Body', null)))
              ]),
            )));
  }
}
