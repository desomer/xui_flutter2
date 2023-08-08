import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/application_manager.dart';

import '../../core/data/core_data.dart';
import '../../core/data/core_provider.dart';
import '../../core/widget/cw_core_loader.dart';
import '../../core/widget/cw_core_widget.dart';

class ArrayBuilder {
  List<Widget> getArrayWidget(String name, CWProvider provider,
      CWWidgetLoaderCtx ctxDesign, String type, BoxConstraints constraints) {
    var listWidget = <Widget>[];
    final CoreDataObjectBuilder builder =
        ctxDesign.collectionDataModel.getClass(provider.type)!;
    //Map<String, dynamic> src = entity.value;
    ColRowLoader? loader;
    switch (type) {
      case "Array":
        loader = AttrArrayLoader(name, ctxDesign, provider);
        break;
      case "List":
        loader = AttrListLoader(name, ctxDesign, provider);
        break;
      case "ReorderList":
        loader = AttrListLoader(name, ctxDesign, provider);
        (loader as AttrListLoader).reorder = true;
        break;
    }

    loader!.ctxLoader.factory.mapProvider[provider.name] = provider;
    ctxDesign.factory.disposePath(name);

    List<CoreDataEntity> listMdel =
        CWApplication.of().dataModelProvider.content;
    CoreDataEntity? aModelToDisplay;

    if (type == "Array") {
      // recherche du model pour afficher les bon label
      for (var element in listMdel) {
        if (element.value["_id_"] == builder.name) {
          aModelToDisplay = element;
          break;
        }
      }
    }

    var allAttribut = builder.getAllAttribut();
    for (final CoreDataAttribut attr in allAttribut) {
      if (attr.type == CDAttributType.CDone) {
        // if (src[attr.name] != null) {
        //   // lien one2one
        // }
      } else if (attr.type == CDAttributType.CDmany) {
      } else {
        //String nameAttr = attr.name;
        Map<String, dynamic> attrDesc = {"name": attr.name};

        if (aModelToDisplay != null) {
          // recherche le label de l'attribut
          List<dynamic> listAttr = aModelToDisplay.value["listAttr"];
          for (Map<String, dynamic> attrModel in listAttr) {
            if (attrModel["_id_"] == attr.name) {
              attrDesc = attrModel;
              break;
            }
          }
        }
        loader.addAttr(attr, attrDesc);
      }
    }

    loader.addRow();

    listWidget.add(Container(
        constraints: BoxConstraints(maxHeight: constraints.maxHeight - 32),
        child: loader.getWidget(name, name)));
    return listWidget;
  }
}

abstract class ColRowLoader extends CWWidgetLoader {
  ColRowLoader(this.name, super.ctx);
  String name;

  void addAttr(CoreDataAttribut attribut, Map<String, dynamic> infoAttr);
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
  void addAttr(CoreDataAttribut attribut, Map<String, dynamic> infoAttr) {
    CWWidgetEvent ctxWE = CWWidgetEvent();
    ctxWE.action = CWProviderAction.onMapWidget.toString();
    ctxWE.provider = provider;
    ctxWE.payload = {'attr': attribut, "infoAttr": infoAttr};
    ctxWE.loader = ctxLoader;

    provider.doAction(null, ctxWE, CWProviderAction.onMapWidget);

    if (ctxWE.retAction != "None") {
      if (ctxWE.ret != null) {
        CoreDataEntity widget = ctxWE.ret;
        widget.value.addAll(<String, dynamic>{
          'bind': attribut.name,
          'providerName': provider.name
        });
        addChildProp('${name}Col0Cont$nbAttr', '${name}Info$nbAttr',
            widget.type, widget);
      } else {
        // type text par defaut
        addWidget('${name}Col0Cont$nbAttr', '${name}Info$nbAttr',
            "CWText", <String, dynamic>{
          'bind': attribut.name,
          'providerName': provider.name
        });
      }

      addWidget('${name}Col0Header$nbAttr', '${name}Head$nbAttr',
          "CWText", <String, dynamic>{
        'label': infoAttr["name"],
      });

      nbAttr++;
    }
  }

  @override
  CoreDataEntity getCWFactory() {
    setProp(
        name,
        ctxLoader.collectionWidget.createEntityByJson(
            'CWExpandPanel', <String, dynamic>{'count': 1}));

    // le titre
    addWidget('${name}Title0', '${name}Title0', "CWText", <String, dynamic>{
      'label': provider.header?.value["label"] ?? provider.type
    });

    // la colonne d'attribut
    addWidget('${name}Body0', '${name}Col0', "CWArray",
        <String, dynamic>{'providerName': provider.name, "count": nbAttr});

    return cwFactory;
  }
}

/////////////////////////////////////////////////////////////////////////
class AttrListLoader extends ColRowLoader {
  AttrListLoader(name, CWWidgetLoaderCtx ctxDesign, this.provider)
      : super(name, ctxDesign) {
    setRoot(name, "CWLoader");
  }

  int nbAttr = 0;
  CWProvider provider;
  bool reorder = false;

  @override
  void addAttr(CoreDataAttribut attribut, Map<String, dynamic> infoAttr) {
    CWWidgetEvent ctxWE = CWWidgetEvent();
    ctxWE.action = CWProviderAction.onMapWidget.toString();
    ctxWE.provider = provider;
    ctxWE.payload = {"attr": attribut, "infoAttr": infoAttr};
    ctxWE.loader = ctxLoader;

    provider.doAction(null, ctxWE, CWProviderAction.onMapWidget);
    if (ctxWE.retAction != "None") {
      if (ctxWE.ret != null) {
        CoreDataEntity widget = ctxWE.ret;
        widget.value.addAll(<String, dynamic>{
          'bind': attribut.name,
          'providerName': provider.name
        });
        addChildProp(
            '${name}RowCont$nbAttr', '${name}Info$nbAttr', widget.type, widget);
      } else {
        // type text par defaut
        addWidget('${name}RowCont$nbAttr', '${name}Info$nbAttr',
            "CWText", <String, dynamic>{
          'bind': attribut.name,
          'providerName': provider.name
        });
      }
      nbAttr++;
    }
  }

  @override
  void addRow() {
    // la colonne d'attribut
    addWidget('${name}Col0Cont', '${name}Row', "CWRow",
        <String, dynamic>{"count": nbAttr});
  }

  @override
  CoreDataEntity getCWFactory() {
    // setProp(
    //     name, ctxLoader.collectionWidget.createEntityByJson('CWLoader', {'providerName': provider.name}));

    // le titre
    addWidget('${name}Cont', '${name}Exp', "CWExpandPanel",
        <String, dynamic>{'count': 1});

    // le titre
    addWidget('${name}ExpTitle0', '${name}Title0', "CWText", <String, dynamic>{
      'label': provider.header?.value["label"] ?? provider.type
    });

    // la colonne d'attribut
    addWidget('${name}ExpBody0', '${name}Col0', "CWList",
        <String, dynamic>{'providerName': provider.name, "reorder": reorder});

    return cwFactory;
  }
}
