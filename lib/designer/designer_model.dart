import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/builder/array_builder.dart';
import 'package:xui_flutter/designer/designer.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';

class DesignerListModel extends StatefulWidget {
  const DesignerListModel({Key? key}) : super(key: key);

  @override
  State<DesignerListModel> createState() => _DesignerListModelState();
}

class _DesignerListModelState extends State<DesignerListModel> {
  @override
  Widget build(BuildContext context) {
    DesignCtx ctx = DesignCtx();
    ctx.mode = ModeRendering.view;
    ctx.collectionWidget = CoreDesigner.ofFactory().collection;
    ctx.collectionAppli = CoreDataCollection();

    ctx.collectionAppli
        .addObject("DataModel")
        .addAttribut("name", CDAttributType.CDtext);

    CoreDataEntity entity =
        ctx.collectionAppli.createEntityByJson("DataModel", {"name": "test"});

    CoreDataEntity entity2 =
        ctx.collectionAppli.createEntityByJson("DataModel", {"name": "test2"});

    var provider = CWProvider()
      ..add(entity)
      ..add(entity2);
    List<Widget> listModel = ArrayBuilder().getArrayWidget(provider, ctx);
    return Column(
      children: listModel,
    );
  }
}

class DesignerModel extends StatefulWidget {
  const DesignerModel({Key? key}) : super(key: key);

  @override
  State<DesignerModel> createState() => _DesignerModelState();
}

class _DesignerModelState extends State<DesignerModel> {
  @override
  Widget build(BuildContext context) {
    DesignCtx ctx = DesignCtx();
    ctx.mode = ModeRendering.view;
    ctx.collectionWidget = CoreDesigner.ofFactory().collection;
    ctx.collectionAppli = CoreDataCollection();

    ctx.collectionAppli.addObject("ModelAttributs")
      ..addAttribut("name", CDAttributType.CDtext)
      ..addAttribut("type", CDAttributType.CDtext);

    CoreDataEntity entity =
        ctx.collectionAppli.createEntityByJson("ModelAttributs", {"name": "nom", "type":"TEXT"});

    CoreDataEntity entity2 =
        ctx.collectionAppli.createEntityByJson("ModelAttributs", {"name": "prenom", "type":"TEXT2"});

    var provider = CWProvider()
      ..add(entity)
      ..add(entity2);

    List<Widget> listModel = ArrayBuilder().getArrayWidget(provider, ctx);
    return Column(
      children: listModel,
    );
  }
}
