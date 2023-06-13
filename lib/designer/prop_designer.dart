import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';

import '../core/data/core_data.dart';

class FormBuilder {
  List<Widget> getFormWidget(
      CoreDataCollection collection, CoreDataEntity entity) {
        
    var listWidget = <Widget>[];

    final CoreDataObjectBuilder builder = collection.getClass(entity.type)!;
    Map<String, dynamic> src = entity.value;

    for (final CoreDataAttribut attr in builder.attributs) {
      if (attr.type == CDAttributType.CDone) {
        if (src[attr.name] != null) {
          // lien one2one
        }
      } else if (attr.type == CDAttributType.CDmany) {
      } else {
        // un attribut
        if (src[attr.name] != null) {
          CWLoader loader = TextLoader(collection, attr);
          final aText = loader.getWidgetEntity();
          listWidget.add(loader.getWidget(aText));
        }
      }
    }
    return listWidget;
  }
}

class TextLoader extends CWLoader {
  TextLoader(super.collection, this.attribut);

  CoreDataAttribut attribut;

  @override
  CoreDataEntity getWidgetEntity() {
    setRoot("CWTextfield");
    setProp(
        "root",
        collection.createEntityByJson(
            'CWTextfield', <String, dynamic>{'label': attribut.name}));
    return aFactory;
  }
}
