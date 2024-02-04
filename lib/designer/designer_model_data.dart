import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_data_filter.dart';

import '../core/data/core_data.dart';
import '../core/data/core_repository.dart';
import '../core/widget/cw_core_bind.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import 'application_manager.dart';
import 'builder/array_builder.dart';
import 'widget_crud.dart';

// ignore: must_be_immutable
class DesignerData extends StatefulWidget {
  ArrayBuilder? arrayBuilder;

  DesignerData({super.key, required this.bindWidget}) {
    bindWidget.fctBindNested = (CoreDataEntity item) {
      var app = CWApplication.of();
      CoreDataFilter filterConfig = CoreDataFilter()..setFilterData(item);
      var modelID = filterConfig.getModelID();
      tableEntity = app.getTableModelByID(modelID);

      if (bindWidget.id == 'bindFilter2Data') {
        CWRepository providerData = app.dataProvider;
        if (filterConfig.isFilter()) {
          providerData.setLoaderTable(modelID);
          providerData.setFilter(filterConfig);
        } else if (filterConfig.isTable()) {
          //filter
          // pas de filtre sur les table
          providerData.setFilter(null);
          providerData.setLoaderTable(modelID);
        }
      }

      // creation du tableau
      CWAppLoaderCtx loader = CWApplication.of().loaderData;
      CWApplication.of().initDataModelWithAttr(loader, tableEntity!);
      CWRepository provider =
          CWApplication.of().getDataProvider(loader, tableEntity!);

      arrayBuilder = ArrayBuilder(loaderCtx: loader, provider: provider);
      arrayBuilder!.initDesignArrayFromLoader('rootData', 'Array');
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

    return LayoutBuilder(builder: (context, constraints) {
      List<Widget> listData =
          widget.arrayBuilder!.getArrayWithConstraint(constraints: constraints);

      listData.add(WidgetAddBtn(
        provider: widget.arrayBuilder!.provider!,
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
