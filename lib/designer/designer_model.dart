import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_data_query.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/designer/builder/array_builder.dart';
import 'package:xui_flutter/designer/designer.dart';
import 'package:xui_flutter/designer/widget_crud.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import 'help/widget_help_bounce.dart';

/// la liste des model
class DesignerListModel extends StatefulWidget {
  const DesignerListModel({super.key});

  @override
  State<DesignerListModel> createState() {
    return _DesignerListModelState();
  }
}

class _DesignerListModelState extends State<DesignerListModel> {
  @override
  Widget build(BuildContext context) {
    var ab = ArrayBuilder();
    return LayoutBuilder(builder: (context, constraints) {
      var arr = ab.getCWArray(
        'rootModel',
        CWApplication.of().dataModelProvider,
        CWApplication.of().loaderModel,
        'List',
      );
      List<Widget> listModel = ArrayBuilder().getArrayWidget(arr, constraints);

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
    CoreGlobalCache.saveCache(CWApplication.of().dataProvider);
    CoreGlobalCache.saveCache(CWApplication.of().dataModelProvider);

    var name = event!.provider?.getSelectedEntity()!.value['name'];

    CWApplication.of()
        .loaderModel
        .findByXid('rootAttrTitle0')!
        .changeProp('label', name);

    CWApplication.of()
        .loaderData
        .findByXid('rootDataTitle0')
        ?.changeProp('label', name);

    CWApplication.of().loaderModel.findWidgetByXid('rootAttrExp')?.repaint();
    // ignore: invalid_use_of_protected_member
    CoreDesigner.of().dataFilterKey.currentState?.setState(() {});
    // ignore: invalid_use_of_protected_member
    CoreDesigner.of().dataKey.currentState?.setState(() {});
  }
}

//////////////////////////////////////////////////////////////////////////////////

class DesignerModel extends StatelessWidget {
  const DesignerModel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: Stack(
        children: [
          Positioned(
              left: 20,
              top: 20,
              width: 300,
              child: Container(
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: const DesignerListAttribut()))
        ],
      ),
    );
  }
}

/// le model (liste des attributs)
class DesignerListAttribut extends StatefulWidget {
  const DesignerListAttribut({super.key});

  @override
  State<DesignerListAttribut> createState() => _DesignerListAttributState();
}

class _DesignerListAttributState extends State<DesignerListAttribut> {
  @override
  Widget build(BuildContext context) {
    var app = CWApplication.of();
    CWProvider providerAttr = app.dataAttributProvider;

    if (app.dataModelProvider.getData().idxSelected > -1) {
      var name =
          app.dataModelProvider.getSelectedEntity()?.value['name'] ?? '?';
      providerAttr.header!.value['label'] = name;
    }

    var ab = ArrayBuilder();
    var arr = ab.getCWArray(
      'rootAttr',
      providerAttr,
      app.loaderModel,
      'ReorderList',
    );

    return LayoutBuilder(builder: (context, constraints) {
      List<Widget> listModel = ArrayBuilder().getArrayWidget(arr, constraints);
      listModel.add(WidgetDrag(provider: providerAttr));
      return Column(children: listModel);
    });
  }
}

class OnAddAttr extends CoreDataAction {
  OnAddAttr(this.provider);
  CWProvider provider;

  @override
  void execute(Object? ctx, CWWidgetEvent? event) {
    // ajout d'un nouveau attribut au model
    CoreDataEntity entity = CWApplication.of().collection.createEntityByJson(
        'ModelAttributs',
        {'name': '?', 'type': event!.payload!.toString().toUpperCase()});

    CWApplication.of().dataAttributProvider.loader!.addData(entity);

    CWApplication.of().loaderModel.findWidgetByXid('rootAttrExp')?.repaint();
  }
}

class OnBuildEdit extends CoreDataAction {
  OnBuildEdit(this.editName, this.displayPrivate);
  List<String> editName;
  bool displayPrivate;

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CoreDataAttribut attr = event!.payload['attr'];
    Map<String, dynamic> infoAttr = event.payload['infoAttr'];

    if (attr.name.startsWith('_')) {
      if (!displayPrivate) {
        event.retAction = 'None';
      }
      return;
    }

    for (var element in editName) {
      if (element == attr.name || element == '*') {
        event.ret = event.loader!.collectionWidget.createEntityByJson(
            'CWTextfield', {'withLabel': false, 'type': infoAttr['type']});
        return;
      }
    }
  }
}
