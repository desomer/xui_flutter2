import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/designer/builder/array_builder.dart';
import 'package:xui_flutter/designer/designer.dart';
import 'package:xui_flutter/designer/widget_create.dart';
import 'package:xui_flutter/widget/cw_textfield.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';

class DesignerListModel extends StatefulWidget {
  DesignerListModel({Key? key}) : super(key: key) {
    DesignerListModel.initModel();
  }

  @override
  State<DesignerListModel> createState() {
    return _DesignerListModelState();
  }

  //static late CWProvider provider;
  static bool isInit = false;

  static initModel() {
    if (isInit) return;
    isInit = true;
    CWApplication.of().initModel();

    // modelCollection.addObject("DataModel")
    //   ..addAttribut("name", CDAttributType.CDtext)
    //   ..addAttribut("listAttr", CDAttributType.CDmany);

    // modelCollection.addObject("ModelAttributs")
    //   ..addAttribut("name", CDAttributType.CDtext)
    //   ..addAttribut("type", CDAttributType.CDtext);

    // provider = CWProvider("DataModel", "DataModel", null);

    // CoreDataEntity entity1 =
    //     modelCollection.createEntityByJson("DataModel", {"name": "Customers"});

    // CoreDataEntity entity2 =
    //     modelCollection.createEntityByJson("DataModel", {"name": "Pets"});

    // entity1.addMany(
    //     modelCollection,
    //     "listAttr",
    //     modelCollection.createEntityByJson(
    //         "ModelAttributs", {"name": "First name", "type": "TEXT"}));
    // entity1.addMany(
    //     modelCollection,
    //     "listAttr",
    //     modelCollection.createEntityByJson(
    //         "ModelAttributs", {"name": "Last name", "type": "TEXT"}));

    // entity2.addMany(
    //     modelCollection,
    //     "listAttr",
    //     modelCollection.createEntityByJson(
    //         "ModelAttributs", {"name": "Name", "type": "TEXT"}));
    // entity2.addMany(
    //     modelCollection,
    //     "listAttr",
    //     modelCollection.createEntityByJson(
    //         "ModelAttributs", {"name": "Category", "type": "TEXT"}));
    // entity2.addMany(
    //     modelCollection,
    //     "listAttr",
    //     modelCollection.createEntityByJson(
    //         "ModelAttributs", {"name": "Breed", "type": "TEXT"}));

    // DesignerListModel.provider
    //   ..add(entity1)
    //   ..add(entity2);
  }

  //static CoreDataCollection modelCollection = CoreDataCollection();
}

class _DesignerListModelState extends State<DesignerListModel> {
  @override
  Widget build(BuildContext context) {
    // CWApplication.of().loaderModel.collectionWidget =
    //     CoreDesigner.ofLoader().ctxLoader.collectionWidget;

    List<Widget> listModel = ArrayBuilder().getArrayWidget("root",
        CWApplication.of().dataModelProvider,
        CWApplication.of().loaderModel,
        AttrRowLoader);
    listModel.add(WidgetAddBtn(
      provider: CWApplication.of().dataModelProvider,
      loader: CWApplication.of().loaderModel,
      repaintXid: "Col0",
    ));
    return Column(
      children: listModel,
    );
  }
}

class OnInsertModel extends CoreDataAction {
  OnInsertModel(this.loader);
  CWWidgetLoaderCtx loader;

  @override
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CoreDataEntity newModel = loader.collectionDataModel
        .createEntityByJson("DataModel", {"name": "?"});
    event!.provider!.content.add(newModel);
  }
}

class OnSelectModel extends CoreDataAction {
  OnSelectModel();

  @override
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    var name = event!.provider?.getSelectedEntity().value["name"];

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
    //CWApplication.of().loaderData.findWidgetByXid("root")?.repaint();
  }
}

class OnBuild extends CoreDataAction {
  OnBuild();

  @override
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    event!.ret = event.loader!.collectionWidget
        .createEntityByJson((CWTextfield).toString(), {"withLabel": false});
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
    // CWApplication.of().loaderAttribut.collectionWidget =
    //     CoreDesigner.ofLoader().ctxLoader.collectionWidget;

    var name =
        CWApplication.of().dataModelProvider.getSelectedEntity().value["name"];

    CWApplication.of().dataAttributProvider.header = CWApplication.of()
        .loaderAttribut
        .collectionDataModel
        .createEntityByJson("DataModel", {"label": name});

    CWApplication.of().dataAttributProvider.actions.clear();
    CWApplication.of()
        .dataAttributProvider
        .addAction(CWProviderAction.onBuild, OnBuildEdit(["name"]));
    CWApplication.of().dataAttributProvider.addAction(
        CWProviderAction.onInsertNone,
        OnAddAttr(CWApplication.of().dataAttributProvider, this));

    List<Widget> listModel = ArrayBuilder().getArrayWidget("rootAttr",
        CWApplication.of().dataAttributProvider,
        CWApplication.of().loaderAttribut,
        AttrRowLoader);
    listModel
        .add(WidgetDrag(provider: CWApplication.of().dataAttributProvider));

    return Column(
      children: listModel,
    );
  }
}

class OnAddAttr extends CoreDataAction {
  OnAddAttr(this.provider, this.widget);
  CWProvider provider;
  State widget;

  @override
  execute(Object? ctx, CWWidgetEvent? event) {
    CoreDataEntity selected = CWApplication.of()
        .dataModelProvider
        .content[CWApplication.of().dataModelProvider.idxSelected];
    List<dynamic>? result = selected.value["listAttr"];

    CoreDataEntity entity = CWApplication.of().collection.createEntityByJson(
        "ModelAttributs",
        {"name": "?", "type": event!.payload!.toString().toUpperCase()});
    result!.add(entity.value);
    // ignore: invalid_use_of_protected_member
    widget.setState(() {});
  }
}

class OnBuildEdit extends CoreDataAction {
  OnBuildEdit(this.editName);
  List<String> editName;

  @override
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CoreDataAttribut attr = event!.payload as CoreDataAttribut;
    for (var element in editName) {
      if (element == attr.name || element == "*") {
        event.ret = event.loader!.collectionWidget
            .createEntityByJson((CWTextfield).toString(), {"withLabel": false});
        return;
      }
    }
  }
}
