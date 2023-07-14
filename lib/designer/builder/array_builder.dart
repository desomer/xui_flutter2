import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/widget/cw_container.dart';
import 'package:xui_flutter/widget/cw_list.dart';
import 'package:xui_flutter/widget/cw_textfield.dart';

import '../../core/data/core_data.dart';
import '../../core/data/core_provider.dart';
import '../../widget/cw_text.dart';

class ArrayBuilder {
  static const providerName = "listObject";

  List<Widget> getArrayWidget(CWProvider provider, DesignCtx ctxDesign) {
    var listWidget = <Widget>[];
    CoreDataEntity entity = provider.getCurrent();

    final CoreDataObjectBuilder builder =
        ctxDesign.collectionAppli.getClass(entity.type)!;
    Map<String, dynamic> src = entity.value;

    AttrRowLoader loader = AttrRowLoader(ctxDesign, entity);

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

    loader.addRow();

    loader.ctxLoader.factory!.mapProvider[providerName] = provider;

    listWidget.add(loader.getWidget());
    return listWidget;
  }
}

class AttrRowLoader extends CWLoader {
  AttrRowLoader(DesignCtx ctxDesign, this.entity) : super(ctxDesign) {
    setRoot("CWExpandPanel");
  }

  int nbAttr = 0;
  CoreDataEntity entity;

  void addAttr(CoreDataAttribut attribut) {
    addWidget('RowCont$nbAttr', 'Info$nbAttr', CWTextfield, <String, dynamic>{
      'bind': attribut.name,
      'providerName': ArrayBuilder.providerName
    });

    nbAttr++;
  }

  void addRow() {
    // la colonne d'attribut
    addWidget('Col0Cont', 'Row', CWRow, <String, dynamic>{"count": nbAttr});
  }

  @override
  CoreDataEntity getCWFactory() {
    setProp(
        "root",
        ctxLoader.collectionWidget.createEntityByJson(
            'CWExpandPanel', <String, dynamic>{'count': 1}));

    // le titre
    addWidget('rootTitle0', 'title0', CWText,
        <String, dynamic>{'label': entity.type});

    // la colonne d'attribut
    addWidget('rootBody0', 'Col0', CWList,
        <String, dynamic>{'providerName': ArrayBuilder.providerName});

    return cwFactory;
  }
}
