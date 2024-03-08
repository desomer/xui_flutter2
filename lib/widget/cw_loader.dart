import 'package:flutter/material.dart';

import '../core/data/core_repository.dart';
import '../core/widget/cw_core_future.dart';
import '../core/widget/cw_core_slot.dart';
import '../core/widget/cw_core_widget.dart';
import '../core/widget/cw_factory.dart';

/// gestion d'un loader (utiliser dans les AttrListLooader)
class CWLoader extends CWWidgetMapRepository {
  const CWLoader({super.key, required super.ctx});

  @override
  StateCW<CWLoader> createState() => _CwLoaderState();

  @override
  void initSlot(String path, ModeParseSlot mode) {
    addSlotPath('$path.Cont', SlotConfig(XidBuilder(tag:'Cont'), ctx.xid), mode);
  }

  static void initFactory(CWWidgetCollectionBuilder c) {
    c.addWidget(
        'CWLoader', (CWWidgetCtx ctx) => CWLoader(key: ctx.getKey(), ctx: ctx));
  }
}

class _CwLoaderState extends StateCW<CWLoader> {
  @override
  Widget build(BuildContext context) {
    var futureData =
        widget.initFutureDataOrNot(CWRepository.of(widget.ctx), widget.ctx);

    Widget getContent(int ok) {
      var provider = CWRepository.of(widget.ctx);
      widget.setProviderDataOK(provider, ok);
      return CWSlot(
          type: 'body',
          key: widget.ctx.getSlotKey('Cont', ''),
          ctx: widget.createChildCtx(widget.ctx, 'Cont', null));
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
