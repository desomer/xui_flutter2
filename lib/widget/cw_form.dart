import '../core/data/core_data.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/cw_factory.dart';
import 'cw_container.dart';

// ignore: must_be_immutable
class CWForm extends CWColumn {
  CWForm({super.key, required super.ctx}) {
    isForm = true;
  }

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget('CWForm',
            (CWWidgetCtx ctx) => CWForm(key: ctx.getKey(), ctx: ctx))
        .addAttr('count', CDAttributType.int)
        .withAction(AttrActionDefault(1))
        .addAttr('fill', CDAttributType.bool)
        .withAction(AttrActionDefault(false))
        .addAttr('providerName', CDAttributType.text)
        ;
  }
  
}
