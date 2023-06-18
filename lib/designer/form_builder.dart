import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';

import '../core/data/core_data.dart';
import '../widget/cw_container.dart';
import '../widget/cw_text.dart';
import '../widget/cw_textfield.dart';
import 'widget_selector.dart';

class FormBuilder {
  List<Widget> getFormWidget(DesignCtx ctxDesign) {
    var listWidget = <Widget>[];

    final CoreDataObjectBuilder builder =
        ctxDesign.collection.getClass(ctxDesign.entity.type)!;
    Map<String, dynamic> src = ctxDesign.entity.value;

    FormLoader loader =
        FormLoader(ctxDesign);
    loader.label = ctxDesign.entity.type;

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

    final aPanel = loader.getWidgetEntity();
    listWidget.add(loader.getWidget(aPanel));
    return listWidget;
  }
}

class FormLoader extends CWLoader {
  FormLoader(DesignCtx ctxDesign) : super(ctxDesign) {
    setRoot("CWExpandPanel");
  }

  int nbAttr = 0;
  String? label;

  void addAttr(CoreDataAttribut attribut) {
    addWidget('Col0Cont$nbAttr', 'attr$nbAttr', CWTextfield, <String, dynamic>{
      'label': attribut.name,
      'bind': attribut.name,
      'providerName': 'Test'
    });
    nbAttr++;
  }

  @override
  CoreDataEntity getWidgetEntity() {
    addWidget(
        'rootTitle0', 'title0', CWText, <String, dynamic>{'label': label});

    addWidget(
        'rootBody0', 'Col0', CWContainer, <String, dynamic>{'count': nbAttr});

    setProp(
        "root",
        ctxDesign.collection.createEntityByJson(
            'CWExpandPanel', <String, dynamic>{'count': 1}));

    return aFactory;
  }
}
