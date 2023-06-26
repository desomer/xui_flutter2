import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/widget/cw_switch.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../widget/cw_container.dart';
import '../widget/cw_text.dart';
import '../widget/cw_textfield.dart';
import 'selector_manager.dart';

class FormBuilder {
  List<Widget> getFormWidget(CWProvider provider, DesignCtx ctxDesign) {
    var listWidget = <Widget>[];
    CoreDataEntity entity = provider.current;

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

    loader.ctxLoader.factory!.mapProvider[ctxDesign.pathWidget] = provider;

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
    if (attribut.type == CDAttributType.CDbool) {
      addWidget(
          'Col0Cont$nbAttr', 'attr$nbAttr', CWSwitch, <String, dynamic>{
        'label': attribut.name,
        'bind': attribut.name,
        'providerName': (ctxLoader as DesignCtx).pathWidget
      });      
    } else {
      addWidget(
          'Col0Cont$nbAttr', 'attr$nbAttr', CWTextfield, <String, dynamic>{
        'label': attribut.name,
        'bind': attribut.name,
        'providerName': (ctxLoader as DesignCtx).pathWidget
      });
    }
    nbAttr++;
  }

  @override
  CoreDataEntity getCWFactory() {
    addWidget('rootTitle0', 'title0', CWText,
        <String, dynamic>{'label': entity.type});

    addWidget(
        'rootBody0', 'Col0', CWColumn, <String, dynamic>{'count': nbAttr, 'fillHeight':false});

    setProp(
        "root",
        ctxLoader.collection.createEntityByJson(
            'CWExpandPanel', <String, dynamic>{'count': 1}));

    return cwFactory;
  }
}
