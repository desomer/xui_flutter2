import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_data_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
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

  static late CWProvider provider;

  static initModel() {
    modelCollection.addObject("DataModel")
      ..addAttribut("name", CDAttributType.CDtext)
      ..addAttribut("listAttr", CDAttributType.CDmany);

    modelCollection.addObject("ModelAttributs")
      ..addAttribut("name", CDAttributType.CDtext)
      ..addAttribut("type", CDAttributType.CDtext);

    provider = CWProvider("DataModel", "DataModel", null);

    CoreDataEntity entity1 =
        modelCollection.createEntityByJson("DataModel", {"name": "Customers"});

    CoreDataEntity entity2 =
        modelCollection.createEntityByJson("DataModel", {"name": "Animal"});

    entity1.addMany(
        modelCollection,
        "listAttr",
        modelCollection.createEntityByJson(
            "ModelAttributs", {"name": "first name", "type": "TEXT"}));
    entity1.addMany(
        modelCollection,
        "listAttr",
        modelCollection.createEntityByJson(
            "ModelAttributs", {"name": "last name", "type": "TEXT"}));

    entity2.addMany(
        modelCollection,
        "listAttr",
        modelCollection.createEntityByJson(
            "ModelAttributs", {"name": "Name", "type": "TEXT"}));
    entity2.addMany(
        modelCollection,
        "listAttr",
        modelCollection.createEntityByJson(
            "ModelAttributs", {"name": "Category", "type": "TEXT"}));
    entity2.addMany(
        modelCollection,
        "listAttr",
        modelCollection.createEntityByJson(
            "ModelAttributs", {"name": "breed", "type": "TEXT"}));

    DesignerListModel.provider
      ..add(entity1)
      ..add(entity2);
  }

  static CoreDataCollection modelCollection = CoreDataCollection();
}

class _DesignerListModelState extends State<DesignerListModel> {
  @override
  Widget build(BuildContext context) {
    CWWidgetLoaderCtx ctx = CWWidgetLoaderCtx();
    ctx.mode = ModeRendering.view;
    ctx.collectionWidget = CoreDesigner.ofLoader().ctxLoader.collectionWidget;
    ctx.collectionAppli = DesignerListModel.modelCollection;

    DesignerListModel.provider
        .addAction(CWProviderAction.onInsertNone, OnInsertModel(ctx));
    DesignerListModel.provider.addAction(CWProviderAction.onBuild, OnBuild());

    DesignerListModel.provider
        .addAction(CWProviderAction.onSelected, OnSelectModel(ctx));

    DesignerListModel.provider.header = ctx.collectionAppli
        .createEntityByJson("DataModel", {"label": "Entity"});

    DesignerListModel.provider.idxSelected = 0;

    List<Widget> listModel =
        ArrayBuilder().getArrayWidget(DesignerListModel.provider, ctx);
    listModel
        .add(WidgetAddBtn(provider: DesignerListModel.provider, loader: ctx));
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
    CoreDataEntity newModel =
        loader.collectionAppli.createEntityByJson("DataModel", {"name": "?"});
    event!.provider!.content.add(newModel);
  }
}

class OnSelectModel extends CoreDataAction {
  OnSelectModel(this.loader);
  CWWidgetLoaderCtx loader;

  @override
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    DesignerModel.loaderAttribut.factory.mapWidgetByXid["Col0"]!.repaint();
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

  static CWWidgetLoaderCtx loaderAttribut = CWWidgetLoaderCtx();
  static bool isInit = false;
  static initModel() {
    if (!isInit) {
      isInit = true;
      loaderAttribut.mode = ModeRendering.view;
      loaderAttribut.collectionWidget =
          CoreDesigner.ofLoader().ctxLoader.collectionWidget;
      loaderAttribut.collectionAppli = DesignerListModel.modelCollection;
    }
  }
}

class _DesignerModelState extends State<DesignerModel> {
  @override
  Widget build(BuildContext context) {
    DesignerModel.initModel();

    var provider = CWProvider(
        "ModelAttributs",
        "ModelAttributs",
        CoreDataLoaderProvider(DesignerModel.loaderAttribut,
            DesignerListModel.provider, "listAttr"));

    List<Widget> listModel =
        ArrayBuilder().getArrayWidget(provider, DesignerModel.loaderAttribut);
    listModel.add(WidgetDrag(provider: provider));

    return Column(
      children: listModel,
    );
  }
}
