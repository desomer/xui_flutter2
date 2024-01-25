import '../core/widget/cw_core_widget.dart';
import '../designer/application_manager.dart';

class CWPageCtx extends CWWidgetVirtual {
  CWPageCtx(super.ctx);

  @override
  void init() {
    var param = ctx.designEntity!.value;
    var app = CWApplication.of();
    var page = app.getEntityPage(param['_id_']);
    if (page == null) {
      var parent = app.getEntityPage(param['parent']);

      var newPage =
          app.collection.createEntityByJson('PageModel', {'name': 'NewPage'});

      var conf = <String, dynamic>{};
      conf.addAll(param);
      conf.remove(r'$type');
      newPage.value.addAll(conf);

      newPage.value['on'] = parent;
      parent?.addMany(app.loaderDesigner, 'subPages', newPage);
      app.initRoutePage();
    }
  }
}
