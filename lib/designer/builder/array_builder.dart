import 'package:flutter/material.dart';
import 'package:xui_flutter/widget/cw_array.dart';

import '../../core/data/core_data.dart';
import '../../core/data/core_provider.dart';
import '../../core/widget/cw_core_loader.dart';
import '../../core/widget/cw_core_widget.dart';
import '../../widget/cw_container.dart';
import '../../widget/cw_list.dart';
import '../../widget/cw_text.dart';

class ArrayBuilder {
  List<Widget> getArrayWidget(String name, CWProvider provider,
      CWWidgetLoaderCtx ctxDesign, Type type) {
    var listWidget = <Widget>[];

    final CoreDataObjectBuilder builder =
        ctxDesign.collectionDataModel.getClass(provider.type)!;
    //Map<String, dynamic> src = entity.value;

    ColRowLoader loader = (type == AttrArrayLoader)
        ? AttrArrayLoader(name, ctxDesign, provider)
        : AttrRowLoader(name, ctxDesign, provider);

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

    listWidget.add(loader.getWidget(name, name));
    return listWidget;
  }
}

abstract class ColRowLoader extends CWWidgetLoader {
  ColRowLoader(this.name, super.ctx);
  String name;

  void addAttr(CoreDataAttribut attribut);
  void addRow() {}
}

class AttrArrayLoader extends ColRowLoader {
  AttrArrayLoader(name, CWWidgetLoaderCtx ctxDesign, this.provider)
      : super(name, ctxDesign) {
    setRoot(name, "CWExpandPanel");
  }

  int nbAttr = 0;
  CWProvider provider;

  @override
  void addAttr(CoreDataAttribut attribut) {
    CWWidgetEvent ctxWE = CWWidgetEvent();
    ctxWE.action = CWProviderAction.onBuild.toString();
    ctxWE.provider = provider;
    ctxWE.payload = attribut;
    ctxWE.loader = ctxLoader;

    addWidget('${name}Col0Header$nbAttr', '${name}Head$nbAttr', CWText, <String, dynamic>{
      'label': attribut.name,
    });

    provider.doAction(null, ctxWE, CWProviderAction.onBuild);
    if (ctxWE.ret != null) {
      CoreDataEntity widget = ctxWE.ret;
      widget.value.addAll(<String, dynamic>{
        'bind': attribut.name,
        'providerName': provider.name
      });
      addChildProp('${name}Col0Cont$nbAttr', '${name}Info$nbAttr', widget.type, widget);
    } else {
      // type text par defaut
      addWidget('${name}Col0Cont$nbAttr', '${name}Info$nbAttr', CWText, <String, dynamic>{
        'bind': attribut.name,
        'providerName': provider.name
      });
    }
    nbAttr++;
  }

  @override
  CoreDataEntity getCWFactory() {
    setProp(
        name,
        ctxLoader.collectionWidget.createEntityByJson(
            'CWExpandPanel', <String, dynamic>{'count': 1}));

    // le titre
    addWidget('${name}Title0', '${name}Title0', CWText, <String, dynamic>{
      'label': provider.header?.value["label"] ?? provider.type
    });

    // la colonne d'attribut
    addWidget('${name}Body0', '${name}Col0', CWArray,
        <String, dynamic>{'providerName': provider.name, "count": nbAttr});

    return cwFactory;
  }
}

/////////////////////////////////////////////////////////////////////////
class AttrRowLoader extends ColRowLoader {
  AttrRowLoader(name, CWWidgetLoaderCtx ctxDesign, this.provider)
      : super(name, ctxDesign) {
    setRoot(name, "CWExpandPanel");
  }

  int nbAttr = 0;
  CWProvider provider;

  @override
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
      addChildProp('${name}RowCont$nbAttr', '${name}Info$nbAttr', widget.type, widget);
    } else {
      // type text par defaut
      addWidget('${name}RowCont$nbAttr', '${name}Info$nbAttr', CWText, <String, dynamic>{
        'bind': attribut.name,
        'providerName': provider.name
      });
    }
    nbAttr++;
  }

  @override
  void addRow() {
    // la colonne d'attribut
    addWidget('${name}Col0Cont', '${name}Row', CWRow, <String, dynamic>{"count": nbAttr});
  }

  @override
  CoreDataEntity getCWFactory() {
    setProp(
        name,
        ctxLoader.collectionWidget.createEntityByJson(
            'CWExpandPanel', <String, dynamic>{'count': 1}));

    // le titre
    addWidget('${name}Title0', '${name}Title0', CWText, <String, dynamic>{
      'label': provider.header?.value["label"] ?? provider.type
    });

    // la colonne d'attribut
    addWidget('${name}Body0', '${name}Col0', CWList,
        <String, dynamic>{'providerName': provider.name});

    return cwFactory;
  }
}
