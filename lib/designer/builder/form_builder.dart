import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/widget/cw_switch.dart';

import '../../core/data/core_data.dart';
import '../../core/data/core_provider.dart';
import '../../widget/cw_container.dart';
import '../../widget/cw_text.dart';
import '../../widget/cw_textfield.dart';

class FormBuilder {
  static const String providerName = "Form";

  List<Widget> getFormWidget(CWProvider provider, CWWidgetLoaderCtx ctxLoader) {
    var listWidget = <Widget>[];
    CoreDataEntity entity = provider.getEntityByIdx(0);

    final CoreDataObjectBuilder builder =
        ctxLoader.collectionWidget.getClass(entity.type)!;
    Map<String, dynamic> src = entity.value;

    ctxLoader.factory.disposePath("root"); 

    AttrFormLoader loader = AttrFormLoader(ctxLoader, entity);
    var allAttribut = builder.getAllAttribut();
    for (final CoreDataAttribut attr in allAttribut) {
      if (attr.type == CDAttributType.CDone) {
        if (src[attr.name] != null) {
          // lien one2one
        }
      } else if (attr.type == CDAttributType.CDmany) {
      } else {
        loader.addAttr(attr);
      }
    }

    loader.ctxLoader.factory.mapProvider[providerName] = provider;

    listWidget.add(loader.getWidget("root", "root"));
    return listWidget;
  }
}

class AttrFormLoader extends CWWidgetLoader {
  AttrFormLoader(CWWidgetLoaderCtx ctxLoader, this.entity) : super(ctxLoader) {
    setRoot("root", "CWExpandPanel");
  }

  int nbAttr = 0;
  CoreDataEntity entity;

  void addAttr(CoreDataAttribut attribut) {
    if (attribut.type == CDAttributType.CDbool) {
      addWidget('Col0Cont$nbAttr', 'attr$nbAttr', CWSwitch, <String, dynamic>{
        'label': attribut.name,
        'bind': attribut.name,
        'providerName': FormBuilder.providerName
      });
    } else {
      addWidget(
          'Col0Cont$nbAttr', 'attr$nbAttr', CWTextfield, <String, dynamic>{
        'label': attribut.name,
        'bind': attribut.name,
        'providerName': FormBuilder.providerName
      });

      // CoreDataEntity ent = cwFactory.getPath(collection, path).getLast();
      // ent.custom[]
      // // print("object $ent");
    }
    nbAttr++;
  }

  @override
  CoreDataEntity getCWFactory() {
    CWProvider? provider = getProvider(FormBuilder.providerName);

    setProp(
        "root",
        ctxLoader.collectionWidget.createEntityByJson(
            'CWExpandPanel', <String, dynamic>{'count': 1}));

    // le titre
    addWidget('rootTitle0', 'title0', CWText, <String, dynamic>{
      'label': provider?.header?.value["label"] ?? entity.type
    });

    // la colonne d'attribut
    addWidget('rootBody0', 'Col0', CWColumn,
        <String, dynamic>{'count': nbAttr, 'fill': false});

    return cwFactory;
  }
}
