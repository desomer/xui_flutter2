import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_data_filter.dart';
import 'package:xui_flutter/core/data/core_data_loader.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_bind.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import 'application_manager.dart';
import 'builder/array_builder.dart';
import 'widget_crud.dart';

// ignore: must_be_immutable
class DesignerData extends StatefulWidget {
  DesignerData({super.key, required this.bindWidget}) {
    bindWidget.fctBindNested = (CoreDataEntity item) {
      //tableEntity = item;
      CoreDataFilter filter = CoreDataFilter()..setFilterData(item);
      var modelID = filter.getModelID();
      tableEntity = CWApplication.of().getTableModelByID(modelID);
      CWProvider providerData = CWApplication.of().dataProvider;
      if (filter.isFilter()) {
        providerData.type = modelID;
        CoreDataLoaderMap dataLoader = providerData.loader as CoreDataLoaderMap;
        dataLoader.setCacheViewID(providerData.getProviderCacheID(),
            onTable: modelID); // choix de la map a afficher
        providerData.setFilter(filter);
      } else {
        providerData.setFilter(null);
      }
    };
  }

  final CWBindWidget bindWidget;
  CoreDataEntity? tableEntity;

  @override
  State<DesignerData> createState() => _DesignerDataState();
}

class _DesignerDataState extends State<DesignerData> {
  @override
  void initState() {
    super.initState();
    widget.bindWidget.nestedWidgetState = this;
  }

  @override
  Widget build(BuildContext context) {
    CWAppLoaderCtx loader = CWApplication.of().loaderData;

    if (widget.tableEntity == null) return const Text('');

    CWApplication.of().initDataModelWithAttr(loader, widget.tableEntity!);
    CWProvider provider =
        CWApplication.of().getDataProvider(loader, widget.tableEntity!);

    var ab = ArrayBuilder();
    var arr = ab.getCWArray('rootData', provider, loader, 'Array');

    return LayoutBuilder(builder: (context, constraints) {
      List<Widget> listData = ArrayBuilder().getArrayWidget(arr, constraints);

      listData.add(WidgetAddBtn(
        provider: provider,
        loader: loader,
        repaintXid: 'rootDataCol0',
      ));

      return Column(
        children: listData,
      );
    });
  }
}

class OnInsertData extends CoreDataAction {
  OnInsertData();

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CoreDataEntity newRow = event!.loader!.collectionDataModel
        .createEntityByJson(event.provider!.type, {});

    event.provider!.addNew(newRow);
  }
}

class SetDate extends CoreDataAction {
  SetDate(this.name);
  String name;

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    event!.provider!
        .getSelectedEntity()!
        .setAttr(ctx!.loader, name, DateTime.timestamp().toIso8601String());
  }
}
