import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/data/core_data_loader.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import 'application_manager.dart';
import 'builder/array_builder.dart';
import 'widget_crud.dart';

class DesignerData extends StatefulWidget {
  const DesignerData({Key? key}) : super(key: key);

  @override
  State<DesignerData> createState() => _DesignerDataState();
}

class _DesignerDataState extends State<DesignerData> {
  @override
  Widget build(BuildContext context) {
    CWWidgetLoaderCtx loader = CWApplication.of().loaderData;

    var selectedEntity =
        CWApplication.of().dataModelProvider.getSelectedEntity();
    if (selectedEntity == null) return const Text('');

    var idData = selectedEntity.value["_id_"];

    initDataModelWithAttr(loader, selectedEntity, idData);
    CWProvider provider =
        getDataProvider(loader, idData, selectedEntity.value["name"]);

    

    return LayoutBuilder(builder: (context, constraints) {
      List<Widget> listData = ArrayBuilder().getArrayWidget(
          "rootData", provider, loader, "Array", constraints);

      listData.add(WidgetAddBtn(
        provider: provider,
        loader: loader,
        repaintXid: "rootDataCol0",
      ));

      return Column(
        children: listData,
      );
    });
  }

  void initDataModelWithAttr(
      CWWidgetLoaderCtx loader, CoreDataEntity selectedEntity, name) {
    var listAttr = selectedEntity.value["listAttr"];

    CoreDataObjectBuilder data = loader.collectionDataModel.addObject(name);
    for (var element in listAttr ?? []) {
      data.addAttribut(element["_id_"], CDAttributType.CDtext);
    }
    data.addGroup(loader.collectionDataModel.getClass("DataEntity")!);
  }

  CWProvider getDataProvider(CWWidgetLoaderCtx loader, idData, label) {
    CWProvider providerData = CWApplication.of().dataProvider;
    providerData.type = idData;
    CoreDataLoaderMap dataLoader = providerData.loader as CoreDataLoaderMap;
    dataLoader.setMapID(idData); // choix de la map a afficher
    providerData.header!.value["label"] = label;

    providerData.idxSelected = 0;
    return providerData;
  }
}

class OnInsertData extends CoreDataAction {
  OnInsertData();

  @override
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CoreDataEntity newRow = event!.loader!.collectionDataModel
        .createEntityByJson(event.provider!.type, {});

    event.provider!.addNew(newRow);
  }
}

class SetDate extends CoreDataAction {
  SetDate(this.name);
  String name;

  @override
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    event!.provider!.getSelectedEntity()!.setAttr(
        ctx!.loader.collectionDataModel,
        name,
        DateTime.timestamp().toIso8601String());
  }
}
