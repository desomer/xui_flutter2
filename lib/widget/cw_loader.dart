import 'package:flutter/material.dart';

import '../core/data/core_provider.dart';
import '../core/widget/cw_core_future.dart';
import '../core/widget/cw_core_slot.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/cw_factory.dart';

class CWLoader extends CWWidgetMap {
  const CWLoader({super.key, required super.ctx});

  @override
  StateCW<CWLoader> createState() => _CwLoaderState();

  @override
  initSlot(String path) {
    addSlotPath('$path.Cont', SlotConfig('${ctx.xid}Cont'));
  }

  static initFactory(CWWidgetCollectionBuilder c) {
    c.addWidget(
        "CWLoader", (CWWidgetCtx ctx) => CWLoader(key: ctx.getKey(), ctx: ctx));
  }
}

class _CwLoaderState extends StateCW<CWLoader> {
  @override
  Widget build(BuildContext context) {
    var futureData = widget.initFutureDataOrNot(CWProvider.of(widget.ctx));

    getContent(int ok) {
      var provider = CWProvider.of(widget.ctx);
      widget.setProviderDataOK(provider, ok);
      return CWSlot( type: "body",
          key: widget.ctx.getSlotKey('Cont', ''),
          ctx: widget.createChildCtx('Cont', null));
    }

    if (futureData is Future) {
      return CWFutureWidget(
        futureData: futureData,
        getContent: getContent,
        nbCol: 1,
      );
    } else {
      return getContent(futureData as int);
    }
  }
}
