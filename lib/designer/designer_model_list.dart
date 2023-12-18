import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/data/core_data_query.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import 'application_manager.dart';
import 'builder/array_builder.dart';
import 'help/widget_help_bounce.dart';
import 'widget_crud.dart';

/// la liste des model
class DesignerListModel extends StatefulWidget {
  const DesignerListModel({super.key});

  @override
  State<DesignerListModel> createState() {
    return _DesignerListModelState();
  }
}

class _DesignerListModelState extends State<DesignerListModel> {
  var arrayBuilder = ArrayBuilder(
      loaderCtx: CWApplication.of().loaderModel,
      provider: CWApplication.of().dataModelProvider);

  @override
  void initState() {
    super.initState();

    arrayBuilder.initDesignArrayFromLoader('rootModel', 'List');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      List<Widget> listModel =
          arrayBuilder.getArrayWithConstraint(constraints: constraints);

      listModel.add(WidgetHelpBounce(
          child: WidgetAddBtn(
        provider: CWApplication.of().dataModelProvider,
        loader: CWApplication.of().loaderModel,
        repaintXid: 'rootModelCol0',
      )));
      return Column(
        children: listModel,
      );
    });
  }
}

class OnInsertModel extends CoreDataAction {
  OnInsertModel(this.loader);
  CWAppLoaderCtx loader;

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CoreDataEntity newModel = loader.collectionDataModel
        .createEntityByJson('DataModel', {'name': '?', 'listAttr': []});
    event!.provider?.addNew(newModel);
  }
}

class OnSelectAttribut extends CoreDataAction {
  OnSelectAttribut();

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CWApplication.of().dataModelProvider.doUserAction(null, null, 'showAttr');
  }
}

class OnSelectModel extends CoreDataAction {
  OnSelectModel();

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    var app = CWApplication.of();
    CoreGlobalCache.saveCache(app.dataProvider);
    CoreGlobalCache.saveCache(app.dataModelProvider);

    var selectedModel = event!.provider?.getSelectedEntity();
    _changeLabelOnAttr(selectedModel!);

    // chargement
    app.bindModel2Attr.onSelect(selectedModel);
    app.bindModel2Filter.onSelect(selectedModel);
    app.bindModel2Data.onSelect(selectedModel);
  }

  void _changeLabelOnAttr(CoreDataEntity selectedModel) {
    var app = CWApplication.of();

    var name = selectedModel.value['name'];

    app.loaderModel.findByXid('rootAttrTitle0')!.changeProp('label', name);
    app.loaderData.findByXid('rootDataTitle0')?.changeProp('label', name);
  }
}