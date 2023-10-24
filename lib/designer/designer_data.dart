import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import 'application_manager.dart';
import 'builder/array_builder.dart';
import 'widget_crud.dart';

class DesignerData extends StatefulWidget {
  const DesignerData({super.key});

  @override
  State<DesignerData> createState() => _DesignerDataState();
}

class _DesignerDataState extends State<DesignerData> {
  @override
  Widget build(BuildContext context) {
    CWAppLoaderCtx loader = CWApplication.of().loaderData;

    var tableEntity = CWApplication.of().dataModelProvider.getSelectedEntity();
    if (tableEntity == null) return const Text('');

    CWApplication.of().initDataModelWithAttr(loader, tableEntity);
    CWProvider provider =
        CWApplication.of().getDataProvider(loader, tableEntity);

    return LayoutBuilder(builder: (context, constraints) {
      List<Widget> listData = ArrayBuilder()
          .getArrayWidget('rootData', provider, loader, 'Array', constraints);

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
