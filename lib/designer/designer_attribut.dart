import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/application_manager.dart';

import '../core/data/core_data.dart';
import '../core/data/core_data_query.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import '../widget/cw_expand_panel.dart';
import 'builder/form_builder.dart';

class DesignerAttribut extends StatefulWidget {
  const DesignerAttribut({Key? key}) : super(key: key);

  @override
  State<DesignerAttribut> createState() => _DesignerAttributState();
}

class _DesignerAttributState extends State<DesignerAttribut> {
  @override
  Widget build(BuildContext context) {
    CWWidgetLoaderCtx loader =
        CWWidgetLoaderCtx().from(CWApplication.of().loaderModel);

    var provider = CWProvider("AttrProvider", 'DataAttribut', null)
      ..add(loader.collectionDataModel.createEntityByJson("DataAttribut", {}));

    provider.header = loader.collectionDataModel
        .createEntityByJson("DataHeader", {"label": "Attribut"});

    deleteAttr(CWWidgetEvent e) async {
      var attrEntity =
          CWApplication.of().dataAttributProvider.getSelectedEntity()!;
      // print(attrEntity!.value);
      attrEntity.operation = CDAction.delete;
      CoreGlobalCacheResultQuery.saveCache(
          CWApplication.of().dataAttributProvider);
      CoreGlobalCacheResultQuery.saveCache(
          CWApplication.of().dataModelProvider);
      CWApplication.of().dataAttributProvider.doEvent(
          CWProviderAction.onStateDelete, CWApplication.of().loaderModel,
          repaintXid: "rootAttrExp");

      //TODO supprimer la colonne de le bdd
    }

    provider.addUserAction("deleteAttr", CoreDataActionFunction(deleteAttr));

    var c = loader.collectionWidget;
    loader.addConstraint('rootTitle0', 'CWExpandConstraint').addMany(
        loader,
        CWExpandAction.actions.toString(),
        c.createEntityByJson("CWAction", {
          "_idAction_": "deleteAttr@AttrProvider",
          "label": "Delete attribut",
          "icon": Icons.delete_forever
        }));

    return Row(children: [
      SizedBox(
          width: 300,
          child:
              Column(children: FormBuilder().getFormWidget(provider, loader)))
    ]);
  }
}
