import 'package:flutter/material.dart';

import 'cw_core_slot.dart';
import 'cw_core_widget.dart';

// ignore: must_be_immutable
class CWFrameDesktop extends CWWidget {
  CWFrameDesktop({super.key, required super.ctx});

  @override
  State<CWFrameDesktop> createState() => _CWFrameDesktop();
  
  @override
  initSlot(String path) {
     addSlotPath('$path.Body', '${ctx.xid}Body');
  }
  

}

class _CWFrameDesktop extends State<CWFrameDesktop> {
  @override
  Widget build(BuildContext context) {
    return CWSlot(
        ctx: widget.ctx,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Mouse Region',
            home: Scaffold(
              appBar: AppBar(
                title: Text(widget.ctx.entity!.getString('title', '?')),
              ),
              body: Column(children: [
                Expanded(
                    child: CWSlot(
                        ctx: CWWidgetCtx(
                            '${widget.ctx.xid}Body',
                            widget.ctx.factory,
                            '${widget.ctx.pathWidget}.Body')))
              ]),
            )));
  }
}
