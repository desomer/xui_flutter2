import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../widget/cw_container.dart';
import '../widget/cw_text.dart';
import '../widget/cw_textfield.dart';
import 'widget_selector.dart';

class FormBuilder {
  List<Widget> getFormWidget(DesignCtx ctxDesign, CoreDataEntity entity) {
    var listWidget = <Widget>[];

    final CoreDataObjectBuilder builder =
        ctxDesign.collection.getClass(entity.type)!;
    Map<String, dynamic> src = entity.value;

    FormLoader loader = FormLoader(ctxDesign, entity);

    for (final CoreDataAttribut attr in builder.attributs) {
      if (attr.type == CDAttributType.CDone) {
        if (src[attr.name] != null) {
          // lien one2one
        }
      } else if (attr.type == CDAttributType.CDmany) {
      } else {
        loader.addAttr(attr);
      }
    }

    loader.ctxLoader.factory!.mapProvider[ctxDesign.pathWidget] =
        CWProvider(entity);

    listWidget.add(loader.getWidget());
    return listWidget;
  }
}

class FormLoader extends CWLoader {
  FormLoader(DesignCtx ctxDesign, this.entity) : super(ctxDesign) {
    setRoot("CWExpandPanel");
  }

  int nbAttr = 0;
  CoreDataEntity entity;

  void addAttr(CoreDataAttribut attribut) {
    addWidget('Col0Cont$nbAttr', 'attr$nbAttr', CWTextfield, <String, dynamic>{
      'label': attribut.name,
      'bind': attribut.name,
      'providerName': (ctxLoader as DesignCtx).pathWidget
    });
    nbAttr++;
  }

  @override
  CoreDataEntity getCWFactory() {
    addWidget(
        'rootTitle0', 'title0', CWText, <String, dynamic>{'label': entity.type});

    addWidget(
        'rootBody0', 'Col0', CWContainer, <String, dynamic>{'count': nbAttr});

    setProp(
        "root",
        ctxLoader.collection.createEntityByJson(
            'CWExpandPanel', <String, dynamic>{'count': 1}));

    return cwFactory;
  }
}
