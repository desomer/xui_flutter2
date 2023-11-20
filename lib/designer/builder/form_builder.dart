import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import '../../core/data/core_data.dart';
import '../../core/data/core_provider.dart';
import '../application_manager.dart';
import '../designer.dart';

class FormBuilder {
  //static const String providerName = "Form";

  List<Widget> getFormWidget(CWProvider provider, CWAppLoaderCtx ctxLoader) {
    var listWidget = <Widget>[];
    CoreDataEntity entity = provider.getEntityByIdx(0);

    CoreDataObjectBuilder? builder =
        ctxLoader.collectionWidget.getClass(entity.type);

    builder ??= ctxLoader.collectionDataModel.getClass(entity.type);

    //Map<String, dynamic> src = entity.value;

    ctxLoader.factory.disposePath('root');

    AttrFormLoader loader =
        AttrFormLoader('rootBody0', ctxLoader, entity, provider, true);
    var allAttribut = builder!.getAllAttribut();
    for (final CoreDataAttribut attr in allAttribut) {
      if (attr.type == CDAttributType.one) {
        //if (src[attr.name] != null) {
        Map<String, dynamic> attrDesc = {
          'name': attr.name,
        }; // par defaut
        loader.addAttr(attr, attrDesc);
        //}
      } else if (attr.type == CDAttributType.many) {
      } else {
        Map<String, dynamic> attrDesc = {'name': attr.name}; // par defaut
        loader.addAttr(attr, attrDesc);
      }
    }

    loader.ctxLoader.factory.mapProvider[provider.name] = provider;

    listWidget.add(loader.getWidget('root', 'root'));
    return listWidget;
  }

  Future<void> createForm(CWWidget widget, CoreDataEntity query) async {
    var app = CWApplication.of();
    // init les data models
    await app.dataModelProvider.getItemsCount(widget.ctx);

    CWProvider provider =
        CWProviderCtx.createFromTable(query.value['_id_'], widget.ctx);

    provider.getData().idxSelected = 0;
    provider.getData().idxDisplayed = 0;

    _createDesign(widget.ctx.loader, provider, widget.ctx.xid,
        widget.ctx.pathWidget, true);

    CoreDesigner.ofView().rebuild();
    // ignore: invalid_use_of_protected_member
    CoreDesigner.of().designerKey.currentState?.setState(() {});
    widget.repaint();
  }

  void _createDesign(CWAppLoaderCtx loaderCtx, CWProvider provider, String xid,
      String path, bool designOnly) {
    final CoreDataObjectBuilder builder =
        loaderCtx.collectionDataModel.getClass(provider.type)!;

    CoreDataEntity entity = provider.getEntityByIdx(0);

    Map<String, dynamic> src = entity.value;

    AttrFormLoader loader =
        AttrFormLoader(xid, loaderCtx, entity, provider, !designOnly);

    List<CoreDataEntity> listMdel =
        CWApplication.of().dataModelProvider.content;
    CoreDataEntity? aModelToDisplay;

    // recherche du model pour afficher les bon label
    for (var element in listMdel) {
      if (element.value['_id_'] == builder.name) {
        aModelToDisplay = element;
        break;
      }
    }

    var allAttribut = builder.getAllAttribut();
    for (final CoreDataAttribut attr in allAttribut) {
      if (attr.type == CDAttributType.one) {
        if (src[attr.name] != null) {
          // lien one2one
        }
      } else if (attr.type == CDAttributType.many) {
      } else {
        Map<String, dynamic> attrDesc = {'name': attr.name}; // par defaut

        if (aModelToDisplay != null) {
          // recherche le label de l'attribut
          attrDesc = CWApplication.of()
                  .getAttributValueById(aModelToDisplay, attr.name) ??
              attrDesc;
        }

        loader.addAttr(attr, attrDesc);
      }
      //if (loader.nbAttr > 0) break;
    }
    loader.ctxLoader.factory.mapProvider[provider.name] = provider;

    loader.addWidget(
        'root', 'provider_${provider.name}', 'CWProvider', <String, dynamic>{
      'type': provider.type,
      'providerName': provider.name
    });

    //loader.addRow();
    if (designOnly) {
      loader.getCWFactory();
    }
  }
}

class AttrFormLoader extends CWWidgetLoader {
  AttrFormLoader(this.xid, CWAppLoaderCtx ctxLoader, this.entity, this.provider,
      this.isRoot)
      : super(ctxLoader) {
    if (isRoot) {
      setRoot('root', 'CWExpandPanel');
    } else {
      tagCol = 'Cont';
    }
  }

  CWProvider provider;
  int nbAttr = 0;
  CoreDataEntity entity;
  bool isRoot;
  String tagCol = 'Col0Cont';
  String xid;

  void addAttr(CoreDataAttribut attribut, Map<String, dynamic> attrDesc) {
    if (!isRoot && attrDesc['name'].toString().startsWith('_')) {
      return;
    }

    if (attribut.type == CDAttributType.bool) {
      addWidget('$xid$tagCol$nbAttr', '${xid}attr$nbAttr',
          'CWSwitch', <String, dynamic>{
        'label': attrDesc['name'],
        'bind': attribut.name,
        'providerName': provider.name
      });
    } else if (attribut.type == CDAttributType.one) {
      if (attribut.typeName == 'icon') {
        addWidget('$xid$tagCol$nbAttr', '${xid}attr$nbAttr',
            'CWSelector', <String, dynamic>{
          'label': attrDesc['name'],
          'type': 'icon',
          'bind': attribut.name,
          'providerName': provider.name
        });
      }
      if (attribut.typeName == 'color') {
        addWidget('$xid$tagCol$nbAttr', '${xid}attr$nbAttr',
            'CWSelector', <String, dynamic>{
          'label': attrDesc['name'],
          'type': 'color',
          'bind': attribut.name,
          'providerName': provider.name
        });
      }
    } else {
      addWidget('$xid$tagCol$nbAttr', '${xid}attr$nbAttr',
          'CWTextfield', <String, dynamic>{
        'label': attrDesc['name'],
        'bind': attribut.name,
        'providerName': provider.name
      });

      // CoreDataEntity ent = cwFactory.getPath(collection, path).getLast();
      // ent.custom[]
      // // print("object $ent");
    }
    nbAttr++;
  }

  @override
  CoreDataEntity getCWFactory() {
    if (isRoot) {
      setProp(
          'root',
          ctxLoader.collectionWidget.createEntityByJson(
              'CWExpandPanel', <String, dynamic>{'count': 1}));

      // le titre
      addWidget('rootTitle0', 'title0', 'CWActionLink', <String, dynamic>{
        'label': provider.header?.value['label'] ?? entity.type,
        '_idAction_': 'onTapHeader@properties'
      });

      // la colonne d'attribut
      addWidget(xid, '${xid}Col0', 'CWColumn',
          <String, dynamic>{'count': nbAttr, 'fill': false});
    } else {
      setProp(
          xid,
          ctxLoader.collectionWidget.createEntityByJson(
              'CWForm', <String, dynamic>{
            'count': nbAttr,
            'fill': false,
            'providerName': provider.name
          }));
    }

    return cwFactory;
  }
}
