import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_data_filter.dart';
import 'package:xui_flutter/designer/application_manager.dart';

import '../../core/data/core_data.dart';
import '../../core/data/core_provider.dart';
import '../../core/widget/cw_core_loader.dart';
import '../../core/widget/cw_core_widget.dart';
import '../designer.dart';

class ArrayBuilder {
  ArrayBuilder({required this.loaderCtx, this.provider});

  CWAppLoaderCtx loaderCtx;
  CWWidget? widget;
  CWProvider? provider;

  void initDesignArrayFromLoader(String name, String type) {
    ColRowLoader? loader = _createDesign(provider!, type, name, name, true);
    widget = loader.getWidget(name, name);
  }

  List<Widget> getArrayWithConstraint({required BoxConstraints constraints}) {
    var listWidget = <Widget>[];

    listWidget.add(Container(
        constraints: BoxConstraints(maxHeight: constraints.maxHeight - 32),
        child: widget));
    return listWidget;
  }

  /// creation d'un array au drop de query
  Future<void> initDesignArrayFromQuery(
      CWWidget widget, CoreDataEntity query, String type) async {
    var app = CWApplication.of();
    // init les data models
    await app.dataModelProvider.getItemsCount(widget.ctx);

    var aFilter = CoreDataFilter()..setFilterData(query);

    provider = CWProviderCtx.createFromTable(
        aFilter.getModelID(), widget.ctx,
        filter: aFilter);

    _createDesign(provider!, type, widget.ctx.xid, widget.ctx.pathWidget, false);

    CoreDesigner.ofView().rebuild();
    // ignore: invalid_use_of_protected_member
    CoreDesigner.of().designerKey.currentState?.setState(() {});
    widget.repaint();
  }

  //////////////////////////////////////////////

  ColRowLoader _createDesign(CWProvider provider, String typeArray, String xid,
      String path, bool isRoot) {
    final CoreDataObjectBuilder builder =
        loaderCtx.collectionDataModel.getClass(provider.type)!;

    late ColRowLoader loader;
    switch (typeArray) {
      case 'None':
        loader = AttrNoneLoader(xid, loaderCtx, provider, isRoot);
        break;
      case 'Array':
        loader = AttrArrayLoader(xid, loaderCtx, provider, isRoot);
        break;
      case 'List':
        loader = AttrListLoader(xid, loaderCtx, provider, isRoot);
        break;
      case 'ReorderList':
        loader = AttrListLoader(xid, loaderCtx, provider, isRoot);
        (loader as AttrListLoader).reorder = true;
        break;
    }

    loader.ctxLoader.factory.mapProvider[provider.id] = provider;
    loader.addWidget(
        'root', 'provider_${provider.id}', 'CWProvider', <String, dynamic>{
      'type': provider.type,
      iDProviderName: provider.id,
      'filter': provider.getFilter()?.dataFilter.value['_id_']
    });

    if (isRoot) {
      // supprimer le path avant reconstruction
      loaderCtx.factory.disposePath(path);
    }

    List<CoreDataEntity> listMdel =
        CWApplication.of().dataModelProvider.content;
    CoreDataEntity? aModelToDisplay;

    if (typeArray == 'Array') {
      // recherche du model pour afficher les bon label
      for (var element in listMdel) {
        if (element.value['_id_'] == builder.name) {
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
        Map<String, dynamic> attrDesc = {'name': attr.name}; // par defaut

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
    if (!isRoot) {
      loader.initCWFactory();
    }
    return loader;
  }
}

/////////////////////////////////////////////////////////////////////////////////////

abstract class ColRowLoader extends CWWidgetLoader {
  ColRowLoader(this.xid, super.ctx);
  String xid;

  void addAttr(CoreDataAttribut attribut, Map<String, dynamic> infoAttr);
  void addRow() {}
}

class AttrNoneLoader extends ColRowLoader {
  AttrNoneLoader(super.xid, super.ctxDesign, this.provider, this.isRoot);

  CWProvider provider;
  bool isRoot;

  @override
  void addAttr(CoreDataAttribut attribut, Map<String, dynamic> infoAttr) {}

  @override
  CoreDataEntity initCWFactory() {
    setProp(
        xid,
        ctxLoader.collectionWidget.createEntityByJson(
            'CWList', <String, dynamic>{iDProviderName: provider.id}));
    return cwFactory;
  }
}

/////////////////////////////////////////////////////////////////////////////////////
class AttrArrayLoader extends ColRowLoader {
  AttrArrayLoader(xid, CWAppLoaderCtx ctxDesign, this.provider, this.isRoot)
      : super(xid, ctxDesign) {
    if (isRoot) {
      setRoot(xid, 'CWExpandPanel');
    }
  }

  int nbAttr = 0;
  CWProvider provider;
  bool isRoot;

  @override
  void addAttr(CoreDataAttribut attribut, Map<String, dynamic> infoAttr) {
    if (!isRoot && infoAttr['name'].toString().startsWith('_')) {
      return;
    }

    String tag = isRoot ? 'Col0' : '';

    CWWidgetEvent ctxWE = CWWidgetEvent();
    ctxWE.action = CWProviderAction.onMapWidget.toString();
    ctxWE.provider = provider;
    ctxWE.payload = {'attr': attribut, 'infoAttr': infoAttr};
    ctxWE.loader = ctxLoader;

    provider.doAction(null, ctxWE, CWProviderAction.onMapWidget);

    if (ctxWE.retAction != 'None') {
      if (ctxWE.ret != null) {
        CoreDataEntity widget = ctxWE.ret;
        widget.value.addAll(<String, dynamic>{
          iDBind: attribut.name,
          iDProviderName: provider.id
        });
        addChildProp('$xid${tag}RowCont$nbAttr', '${xid}Cell$nbAttr',
            widget.type, widget);
      } else {
        // type text par defaut
        addWidget('$xid${tag}RowCont$nbAttr', '${xid}Cell$nbAttr',
            'CWText', <String, dynamic>{
          iDBind: attribut.name,
          iDProviderName: provider.id
        });
      }

      addWidget('$xid${tag}Header$nbAttr', '${xid}Head$nbAttr',
          'CWText', <String, dynamic>{
        'label': infoAttr['name'],
      });

      nbAttr++;
    }
  }

  @override
  CoreDataEntity initCWFactory() {
    if (!isRoot) {
      // array sans header expandable
      setProp(
          xid,
          ctxLoader.collectionWidget.createEntityByJson('CWArray',
              <String, dynamic>{iDProviderName: provider.id, 'count': nbAttr}));
    } else {
      // array avec header expandable
      setProp(
          xid,
          ctxLoader.collectionWidget.createEntityByJson(
              'CWExpandPanel', <String, dynamic>{'count': 1}));

      // le titre
      addWidget('${xid}Title0', '${xid}Title0', 'CWText', <String, dynamic>{
        'label': provider.header?.value['label'] ?? provider.type
      });

      // la colonne d'attribut
      addWidget('${xid}Body0', '${xid}Col0', 'CWArray',
          <String, dynamic>{iDProviderName: provider.id, 'count': nbAttr});
    }
    return cwFactory;
  }
}

/////////////////////////////////////////////////////////////////////////
class AttrListLoader extends ColRowLoader {
  AttrListLoader(xid, CWAppLoaderCtx ctxDesign, this.provider, this.isRoot)
      : super(xid, ctxDesign) {
    setRoot(xid, 'CWLoader');
  }

  int nbAttr = 0;
  CWProvider provider;
  bool reorder = false;
  bool isRoot;

  @override
  void addAttr(CoreDataAttribut attribut, Map<String, dynamic> infoAttr) {
    CWWidgetEvent ctxWE = CWWidgetEvent();
    ctxWE.action = CWProviderAction.onMapWidget.toString();
    ctxWE.provider = provider;
    ctxWE.payload = {'attr': attribut, 'infoAttr': infoAttr};
    ctxWE.loader = ctxLoader;

    provider.doAction(null, ctxWE, CWProviderAction.onMapWidget);
    if (ctxWE.retAction != 'None') {
      if (ctxWE.ret != null) {
        CoreDataEntity widget = ctxWE.ret;
        widget.value.addAll(<String, dynamic>{
          iDBind: attribut.name,
          iDProviderName: provider.id
        });
        addChildProp(
            '${xid}RowCont$nbAttr', '${xid}Info$nbAttr', widget.type, widget);
      } else {
        // type text par defaut
        addWidget('${xid}RowCont$nbAttr', '${xid}Info$nbAttr',
            'CWText', <String, dynamic>{
          iDBind: attribut.name,
          iDProviderName: provider.id
        });
      }
      nbAttr++;
    }
  }

  @override
  void addRow() {
    // la colonne d'attribut
    addWidget('${xid}Col0Cont', '${xid}Row', 'CWRow',
        <String, dynamic>{'count': nbAttr});
  }

  @override
  CoreDataEntity initCWFactory() {
    // le expandPanel
    addWidget('${xid}Cont', '${xid}Exp', 'CWExpandPanel',
        <String, dynamic>{'count': 1});

    // le titre
    addWidget('${xid}ExpTitle0', '${xid}Title0', 'CWText', <String, dynamic>{
      'label': provider.header?.value['label'] ?? provider.type
    });

    // la colonne d'attribut
    addWidget('${xid}ExpBody0', '${xid}Col0', 'CWList',
        <String, dynamic>{iDProviderName: provider.id, 'reorder': reorder});

    return cwFactory;
  }
}
