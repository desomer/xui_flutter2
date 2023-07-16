import 'package:flutter/material.dart';

import '../../core/data/core_data.dart';
import '../../core/data/core_provider.dart';
import '../../core/widget/cw_core_loader.dart';
import '../../core/widget/cw_core_widget.dart';
import '../../widget/cw_container.dart';
import '../../widget/cw_list.dart';
import '../../widget/cw_text.dart';

class ArrayBuilder {

  List<Widget> getArrayWidget(
      CWProvider provider, CWWidgetLoaderCtx ctxDesign) {
    var listWidget = <Widget>[];

    final CoreDataObjectBuilder builder =
        ctxDesign.collectionAppli.getClass(provider.type)!;
    //Map<String, dynamic> src = entity.value;

    ctxDesign.createFactory();
    AttrRowLoader loader = AttrRowLoader(ctxDesign, provider);
    loader.ctxLoader.factory.mapProvider[provider.name] = provider;

    for (final CoreDataAttribut attr in builder.attributs) {
      if (attr.type == CDAttributType.CDone) {
        // if (src[attr.name] != null) {
        //   // lien one2one
        // }
      } else if (attr.type == CDAttributType.CDmany) {
      } else {
        loader.addAttr(attr);
      }
    }

    loader.addRow();

    listWidget.add(loader.getWidget());
    return listWidget;
  }
}

class AttrRowLoader extends CWWidgetLoader {
  AttrRowLoader(CWWidgetLoaderCtx ctxDesign, this.provider)
      : super(ctxDesign) {
    setRoot("CWExpandPanel");
  }

  int nbAttr = 0;
  CWProvider provider;

  void addAttr(CoreDataAttribut attribut) {

    CWWidgetEvent ctxWE = CWWidgetEvent();
    ctxWE.action = CWProviderAction.onBuild.toString();
    ctxWE.provider = provider;
    ctxWE.payload = attribut;
    ctxWE.loader = ctxLoader;

    provider.doAction(null, ctxWE, CWProviderAction.onBuild);
    if (ctxWE.ret != null) {
      CoreDataEntity widget = ctxWE.ret;
      widget.value.addAll(<String, dynamic>{
        'bind': attribut.name,
        'providerName': provider.name
      });

      addChildProp('RowCont$nbAttr', 'Info$nbAttr', widget.type, widget);
    } else {
      addWidget('RowCont$nbAttr', 'Info$nbAttr', CWText, <String, dynamic>{
        'bind': attribut.name,
        'providerName': provider.name
      });
    }
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
    addWidget('rootTitle0', 'title0', CWText, <String, dynamic>{
      'label': provider.header?.value["label"] ?? provider.type
    });

    // la colonne d'attribut
    addWidget('rootBody0', 'Col0', CWList,
        <String, dynamic>{'providerName': provider.name});

    return cwFactory;
  }
}
