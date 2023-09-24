import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/widget/cw_array.dart';

import '../../core/data/core_data.dart';
import '../../core/data/core_provider.dart';
import '../../core/widget/cw_core_loader.dart';
import '../../core/widget/cw_core_widget.dart';
import '../designer.dart';

class ArrayBuilder {
  List<Widget> getArrayWidget(String name, CWProvider provider,
      CWAppLoaderCtx loaderCtx, String type, BoxConstraints constraints) {
    var listWidget = <Widget>[];
    ColRowLoader? loader =
        initDesign(loaderCtx, provider, type, name, name, false);

    listWidget.add(Container(
        constraints: BoxConstraints(maxHeight: constraints.maxHeight - 32),
        child: loader.getWidget(name, name)));
    return listWidget;
  }

  /// creation d'un array au drop de query
  initArray(CWArray widget, CoreDataEntity query) async {
    var app = CWApplication.of();
    await app.dataModelProvider.getItemsCount();

    List<CoreDataEntity> listTableEntity = app.dataModelProvider.content;

    var tableEntity = listTableEntity.firstWhere((CoreDataEntity element) =>
        element.value["_id_"] == query.value["_id_"]);

    app.initDataModelWithAttr(widget.ctx.loader, tableEntity);
    CWProvider provider = widget.ctx.factory.loader.mode == ModeRendering.design
        ? app.getDesignDataProvider(widget.ctx.loader, tableEntity)
        : app.getDataProvider(widget.ctx.loader, tableEntity);

    ArrayBuilder().initDesign(widget.ctx.loader, provider, "Array",
        widget.ctx.xid, widget.ctx.pathWidget, true);

    CoreDesigner.ofView().rebuild();
    // ignore: invalid_use_of_protected_member
    CoreDesigner.of().designerKey.currentState?.setState(() {});
    widget.repaint();
  }

  ColRowLoader initDesign(CWAppLoaderCtx loaderCtx, CWProvider provider,
      String typeArray, String xid, String path, bool designOnly) {
    final CoreDataObjectBuilder builder =
        loaderCtx.collectionDataModel.getClass(provider.type)!;

    late ColRowLoader loader;
    switch (typeArray) {
      case "Array":
        loader = AttrArrayLoader(xid, loaderCtx, provider, designOnly);
        break;
      case "List":
        loader = AttrListLoader(xid, loaderCtx, provider);
        break;
      case "ReorderList":
        loader = AttrListLoader(xid, loaderCtx, provider);
        (loader as AttrListLoader).reorder = true;
        break;
    }

    loader.ctxLoader.factory.mapProvider[provider.name] = provider;
    if (!designOnly) {
      loaderCtx.factory.disposePath(path);
    }

    List<CoreDataEntity> listMdel =
        CWApplication.of().dataModelProvider.content;
    CoreDataEntity? aModelToDisplay;

    if (typeArray == "Array") {
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
      if (attr.type == CDAttributType.one) {
        // if (src[attr.name] != null) {
        //   // lien one2one
        // }
      } else if (attr.type == CDAttributType.many) {
      } else {
        //String nameAttr = attr.name;
        Map<String, dynamic> attrDesc = {"name": attr.name}; // par defaut

        if (aModelToDisplay != null) {
          // recherche le label de l'attribut
          attrDesc = CWApplication.of()
                  .getAttributValueById(aModelToDisplay, attr.name) ??
              attrDesc;
        }
        loader.addAttr(attr, attrDesc);
      }
    }

    loader.addRow();
    if (designOnly) {
      loader.getCWFactory();
    }
    return loader;
  }
}

abstract class ColRowLoader extends CWWidgetLoader {
  ColRowLoader(this.xid, super.ctx);
  String xid;

  void addAttr(CoreDataAttribut attribut, Map<String, dynamic> infoAttr);
  void addRow() {}
}

/////////////////////////////////////////////////////////////////////////////////////
class AttrArrayLoader extends ColRowLoader {
  AttrArrayLoader(xid, CWAppLoaderCtx ctxDesign, this.provider, this.arrayOnly)
      : super(xid, ctxDesign) {
    if (!arrayOnly) {
      setRoot(xid, "CWExpandPanel");
    }
  }

  int nbAttr = 0;
  CWProvider provider;
  bool arrayOnly;

  @override
  void addAttr(CoreDataAttribut attribut, Map<String, dynamic> infoAttr) {
    String tag = arrayOnly ? "" : "Col0";

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
        addChildProp('$xid${tag}RowCont$nbAttr', '${xid}Cell$nbAttr',
            widget.type, widget);
      } else {
        // type text par defaut
        addWidget('$xid${tag}RowCont$nbAttr', '${xid}Cell$nbAttr',
            "CWText", <String, dynamic>{
          'bind': attribut.name,
          'providerName': provider.name
        });
      }

      addWidget('$xid${tag}Header$nbAttr', '${xid}Head$nbAttr',
          "CWText", <String, dynamic>{
        'label': infoAttr["name"],
      });

      nbAttr++;
    }
  }

  @override
  CoreDataEntity getCWFactory() {
    if (arrayOnly) {
      // array sans header expandable
      setProp(
          xid,
          ctxLoader.collectionWidget.createEntityByJson(
              "CWArray", <String, dynamic>{
            'providerName': provider.name,
            "count": nbAttr
          }));
    } else {
      // array avec header expandable
      setProp(
          xid,
          ctxLoader.collectionWidget.createEntityByJson(
              'CWExpandPanel', <String, dynamic>{'count': 1}));

      // le titre
      addWidget('${xid}Title0', '${xid}Title0', "CWText", <String, dynamic>{
        'label': provider.header?.value["label"] ?? provider.type
      });

      // la colonne d'attribut
      addWidget('${xid}Body0', '${xid}Col0', "CWArray",
          <String, dynamic>{'providerName': provider.name, "count": nbAttr});
    }
    return cwFactory;
  }
}

/////////////////////////////////////////////////////////////////////////
class AttrListLoader extends ColRowLoader {
  AttrListLoader(xid, CWAppLoaderCtx ctxDesign, this.provider)
      : super(xid, ctxDesign) {
    setRoot(xid, "CWLoader");
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
            '${xid}RowCont$nbAttr', '${xid}Info$nbAttr', widget.type, widget);
      } else {
        // type text par defaut
        addWidget('${xid}RowCont$nbAttr', '${xid}Info$nbAttr',
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
    addWidget('${xid}Col0Cont', '${xid}Row', "CWRow",
        <String, dynamic>{"count": nbAttr});
  }

  @override
  CoreDataEntity getCWFactory() {
    // le expandPanel
    addWidget('${xid}Cont', '${xid}Exp', "CWExpandPanel",
        <String, dynamic>{'count': 1});

    // le titre
    addWidget('${xid}ExpTitle0', '${xid}Title0', "CWText", <String, dynamic>{
      'label': provider.header?.value["label"] ?? provider.type
    });

    // la colonne d'attribut
    addWidget('${xid}ExpBody0', '${xid}Col0', "CWList",
        <String, dynamic>{'providerName': provider.name, "reorder": reorder});

    return cwFactory;
  }
}
