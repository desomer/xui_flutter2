import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_data_query.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/designer/builder/array_builder.dart';
import 'package:xui_flutter/designer/designer.dart';
import 'package:xui_flutter/designer/widget_crud.dart';
import 'package:xui_flutter/widget/cw_textfield.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';

class DesignerListModel extends StatefulWidget {
  const DesignerListModel({Key? key}) : super(key: key);

  @override
  State<DesignerListModel> createState() {
    return _DesignerListModelState();
  }
}

class _DesignerListModelState extends State<DesignerListModel> {
  @override
  Widget build(BuildContext context) {
    //DesignerListModel.initModel();

    return LayoutBuilder(builder: (context, constraints) {
      List<Widget> listModel = ArrayBuilder().getArrayWidget(
          "root",
          CWApplication.of().dataModelProvider,
          CWApplication.of().loaderModel,
          AttrListLoader,
          constraints);

      listModel.add(WidgetAddBtn(
        provider: CWApplication.of().dataModelProvider,
        loader: CWApplication.of().loaderModel,
        repaintXid: "rootCol0",
      ));
      return Column(
        children: listModel,
      );
    });
  }
}

class OnInsertModel extends CoreDataAction {
  OnInsertModel(this.loader);
  CWWidgetLoaderCtx loader;

  @override
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CoreDataEntity newModel = loader.collectionDataModel
        .createEntityByJson("DataModel", {"name": "?", "listAttr": []});
    event!.provider!.loader!.addData(newModel);
  }
}

class OnSelectModel extends CoreDataAction {
  OnSelectModel();

  @override
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CacheResultQuery.saveCache(CWApplication.of().dataProvider); 
    CacheResultQuery.saveCache(CWApplication.of().dataModelProvider);

    var name = event!.provider?.getSelectedEntity()!.value["name"];

    CWApplication.of()
        .loaderAttribut
        .findByXid("rootAttrTitle0")!
        .changeProp("label", name);

    CWApplication.of()
        .loaderData
        .findByXid("rootDataTitle0")
        ?.changeProp("label", name);

    // ignore: invalid_use_of_protected_member
    CoreDesigner.of().dataKey.currentState?.setState(() {});
    CWApplication.of().loaderAttribut.findWidgetByXid("rootAttr")?.repaint();
  }
}

//////////////////////////////////////////////////////////////////////////////////
class DesignerModel extends StatefulWidget {
  const DesignerModel({Key? key}) : super(key: key);

  @override
  State<DesignerModel> createState() => _DesignerModelState();
}

class _DesignerModelState extends State<DesignerModel> {
  @override
  Widget build(BuildContext context) {
    CWProvider providerAttr = CWApplication.of().dataAttributProvider;

    if (CWApplication.of().dataModelProvider.idxSelected > -1) {
      var name = CWApplication.of()
              .dataModelProvider
              .getSelectedEntity()
              ?.value["name"] ?? "?";
      providerAttr.header!.value["label"] = name;
    }

    return LayoutBuilder(builder: (context, constraints) {
      List<Widget> listModel = ArrayBuilder().getArrayWidget(
          "rootAttr",
          providerAttr,
          CWApplication.of().loaderAttribut,
          AttrListLoader,
          constraints);
      listModel.add(WidgetDrag(provider: providerAttr));
      return Column(children: listModel);
    });
  }
}

class OnAddAttr extends CoreDataAction {
  OnAddAttr(this.provider);
  CWProvider provider;

  @override
  execute(Object? ctx, CWWidgetEvent? event) {
    // ajout d'un nouveau attribut au model
    CoreDataEntity entity = CWApplication.of().collection.createEntityByJson(
        "ModelAttributs",
        {"name": "?", "type": event!.payload!.toString().toUpperCase()});

    CWApplication.of().dataAttributProvider.loader!.addData(entity);

    CWApplication.of().loaderAttribut.findWidgetByXid("rootAttr")?.repaint();
  }
}

class OnBuildEdit extends CoreDataAction {
  OnBuildEdit(this.editName, this.displayPrivate);
  List<String> editName;
  bool displayPrivate;

  @override
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CoreDataAttribut attr = event!.payload as CoreDataAttribut;
    if (attr.name.startsWith("_")) {
      if (!displayPrivate) {
        event.retAction = "None";
      }
      return;
    }

    for (var element in editName) {
      if (element == attr.name || element == "*") {
        event.ret = event.loader!.collectionWidget
            .createEntityByJson((CWTextfield).toString(), {"withLabel": false});
        return;
      }
    }
  }
}
