import '../core/data/core_data.dart';
import '../core/data/core_repository.dart';
import '../core/widget/cw_core_widget.dart';
import '../core/widget/cw_factory.dart';
import 'cw_container.dart';

// ignore: must_be_immutable
class CWForm extends CWColumn {
  static double getHeightRow(CWWidget widget) {
    return widget.ctx.loader.modeDesktop ? 36 : 52;
  }

  CWForm({super.key, required super.ctx}) {
    isForm = true;
  }

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget(
            'CWForm', (CWWidgetCtx ctx) => CWForm(key: ctx.getKey(), ctx: ctx))
        .addAttr(iDCount, CDAttributType.int)
        .withAction(AttrActionDefault(0))
        .addAttr('fill', CDAttributType.bool)
        .withAction(AttrActionDefault(false))
        .addAttr(iDProviderName, CDAttributType.text, tname: 'provider')
        .addAttr('runSpacing', CDAttributType.int)
        .withAction(AttrActionDefault(8))
        .addAttr('_style_', CDAttributType.one, tname: 'StyleModel')
        .withAction(AttrActionDefault( { 'bSize' : 8.0 }))
    ;
  }
}
