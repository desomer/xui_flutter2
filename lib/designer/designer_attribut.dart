import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/application_manager.dart';

import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
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

    var provider = CWProvider("properties", 'DataAttribut', null)
        ..add(loader.collectionDataModel.createEntityByJson("DataAttribut", {}));

    provider.header =
        loader.collectionDataModel.createEntityByJson("DataHeader", {"label": "Attribut"});

    var c = loader.collectionWidget;
    loader
        .addConstraint('rootTitle0', 'CWExpandConstraint')
        .addMany(
            c,
            "actions",
            c.createEntityByJson("CWAction", {
              "_idAction_": "delete@DataModelProvider",
              "label": "Delete attribut",
              "icon": Icons.delete_forever
            }));

    return Row(children: [ SizedBox(width: 300, child :Column(children:  FormBuilder().getFormWidget(provider, loader))) ]);
  }
}
