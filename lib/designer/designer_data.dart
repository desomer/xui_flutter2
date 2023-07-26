import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import 'application_manager.dart';
import 'builder/array_builder.dart';
import 'designer_model.dart';
import 'widget_create.dart';

class DesignerData extends StatefulWidget {
  const DesignerData({Key? key}) : super(key: key);

  @override
  State<DesignerData> createState() => _DesignerDataState();
}

class _DesignerDataState extends State<DesignerData> {
  @override
  Widget build(BuildContext context) {
    CWWidgetLoaderCtx loader = CWApplication.of().loaderData;
    loader.collectionDataModel = CoreDataCollection();

    var selectedEntity =
        CWApplication.of().dataModelProvider.getSelectedEntity();

    var name = selectedEntity.value["name"];

    initDataModel(loader, selectedEntity, name);
    CWProvider provider = getDataProvider(loader, name);

    List<Widget> listModel =
        ArrayBuilder().getArrayWidget("rootData", provider, loader, AttrArrayLoader);
    listModel.add(WidgetAddBtn(
      provider: provider,
      loader: loader,
      repaintXid: "rootDataCol0",
    ));

    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: listModel,
        ));
  }

  void initDataModel(
      CWWidgetLoaderCtx loader, CoreDataEntity selectedEntity, name) {
    var listAttr = selectedEntity.value["listAttr"];

    loader.collectionDataModel.addObject("DataModel")
      ..addAttribut("name", CDAttributType.CDtext)
      ..addAttribut("listAttr", CDAttributType.CDmany);

    CoreDataObjectBuilder data = loader.collectionDataModel.addObject(name);
    for (var element in listAttr??[]) {
      data.addAttribut(element["name"], CDAttributType.CDtext);
    }
  }

  CWProvider getDataProvider(CWWidgetLoaderCtx loader, name) {
    CWProvider provider = CWProvider("ListData", name, null);

    provider.content
        .add(loader.collectionDataModel.createEntityByJson(name, {}));

    provider.header = loader.collectionDataModel
        .createEntityByJson("DataModel", {"label": name});

    provider.actions.clear();
    provider.addAction(CWProviderAction.onBuild, OnBuildEdit(["*"]));
    provider.addAction(
        CWProviderAction.onInsertNone, OnInsertData(loader, name));

    provider.idxSelected = 0;
    return provider;
  }
}

class OnInsertData extends CoreDataAction {
  OnInsertData(this.loader, this.type);
  CWWidgetLoaderCtx loader;
  String type;

  @override
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CoreDataEntity newModel =
        loader.collectionDataModel.createEntityByJson(type, {});
    event!.provider!.content.add(newModel);
  }
}
