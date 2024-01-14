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

    ctxLoader.factory.disposePath('root');

    AttrFormLoader loader =
        AttrFormLoader('rootBody0', ctxLoader, entity.type, provider, true);
    var allAttribut = builder!.getAllAttribut();
    for (final CoreDataAttribut attr in allAttribut) {
      if (attr.type == CDAttributType.one) {
        //if (src[attr.name] != null) {

        loader.addAttr(attr);
        //}
      } else if (attr.type == CDAttributType.many) {
        // arrat
      } else {
        loader.addAttr(attr);
      }
    }

    loader.ctxLoader.addProvider(provider);

    listWidget.add(loader.getWidget('root', 'root'));
    return listWidget;
  }

  Future<void> createForm(CWWidget widget, CoreDataEntity query) async {
    var app = CWApplication.of();
    // init les data models
    await app.dataModelProvider.getItemsCount(widget.ctx);

    CWProvider provider = app.getProviderFromQuery(query, widget);

    //provider.getData().idxSelected = 0;
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
        AttrFormLoader(xid, loaderCtx, entity.type, provider, !designOnly);

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
        if (aModelToDisplay != null) {
          // recherche le label de l'attribut
          attr.label = CWApplication.of()
              .getAttributValueById(aModelToDisplay, attr.name)?['name'];
        }

        loader.addAttr(attr);
      }
      //if (loader.nbAttr > 0) break;
    }
    loader.ctxLoader.addProvider(provider);

    loader.addWidget('root', 'provider_${provider.id}', 'CWProvider',
        <String, dynamic>{'type': provider.type, iDProviderName: provider.id});

    //loader.addRow();
    if (designOnly) {
      loader.initCWFactory();
    }
  }
}

class AttrFormLoader extends CWWidgetLoader {
  AttrFormLoader(this.xid, CWAppLoaderCtx ctxLoader, this.nameForm,
      this.provider, this.isRoot,
      {this.mode})
      : super(ctxLoader) {
    if (isRoot) {
      if (mode == 'col') {
        setRoot('root', 'CWColumn');
        tagCol = 'Cont';
      } else {
        setRoot('root', 'CWExpandPanel');
      }
    } else {
      tagCol = 'Cont';
    }
  }

  CWProvider provider;
  int nbAttr = 0;
  String nameForm;
  bool isRoot;
  String tagCol = 'Col0Cont';
  String xid;
  String? mode;

  void addAttr(CoreDataAttribut attribut) {
    String name = attribut.label ?? attribut.name;

    if (/*!isRoot && */ name.startsWith('_')) {
      return;
    }

    String inSlot = '$xid$tagCol$nbAttr';
    bool addBind = attribut.customValue?['bindEnable'] ?? false; //isRoot;
    if (addBind) {
      addWidget(
          '$xid$tagCol$nbAttr', '${xid}row$nbAttr', 'CWRow', <String, dynamic>{
        iDCount: 2,
      });

      String inSlotBind = '${xid}row${nbAttr}Cont0';

      // le button de binding
      addWidget(
          inSlotBind, '${xid}bind$nbAttr', 'CWSelector', <String, dynamic>{
        '_idAction_': 'onTapLink@properProvider',
        'type': 'bind',
        iDBind: '@${attribut.name}',
        iDProviderName: provider.id
      });

      var constraint =
          collection.createEntityByJson('CWRowConstraint', <String, dynamic>{
        'width': 20,
      });

      setConstraint(inSlotBind, constraint);
      inSlot = '${xid}row${nbAttr}Cont1';
    }

    if (attribut.type == CDAttributType.bool) {
      addWidget(inSlot, '${xid}attr$nbAttr', 'CWSwitch', <String, dynamic>{
        'label': name,
        iDBind: attribut.name,
        iDProviderName: provider.id
      });
    } else if (attribut.type == CDAttributType.one) {
      addWidget(inSlot, '${xid}attr$nbAttr', 'CWSelector', <String, dynamic>{
        'label': name,
        'type': attribut.typeName,
        iDBind: attribut.name,
        iDProviderName: provider.id,
        'customValue': attribut.customValue
      });
    } else if (attribut.typeName != null) {
      if (attribut.typeName == 'toogle') {
        addWidget(inSlot, '${xid}attr$nbAttr', 'CWToogle', <String, dynamic>{
          'label': name,
          '@bind': {iDBind: attribut.name, iDProviderName: provider.id},
          'bindValue': attribut.customValue?['bindValue']
        });
      } else {
        addWidget(inSlot, '${xid}attr$nbAttr', 'CWSelector', <String, dynamic>{
          'label': name,
          'type': attribut.typeName,
          iDBind: attribut.name,
          iDProviderName: provider.id,
          'customValue': attribut.customValue
        });
      }
    } else {
      addWidget(inSlot, '${xid}attr$nbAttr', 'CWTextfield', <String, dynamic>{
        'label': name,
        'type': attribut.type.name.toUpperCase(),
        '@bind': {iDBind: attribut.name, iDProviderName: provider.id}
      });
    }
    nbAttr++;
  }

  @override
  CoreDataEntity initCWFactory() {
    if (isRoot) {
      if (mode == 'col') {
        setProp(
            'root',
            ctxLoader.collectionWidget.createEntityByJson(
                'CWColumn', <String, dynamic>{iDCount: nbAttr, 'fill': false}));
      } else {
        setProp(
            'root',
            ctxLoader.collectionWidget.createEntityByJson(
                'CWExpandPanel', <String, dynamic>{iDCount: 1}));

        // le titre
        addWidget('rootTitle0', 'title0', 'CWActionLink', <String, dynamic>{
          'label': provider.header?.value['label'] ?? nameForm,
          '_idAction_': 'onTapHeader@properProvider'
        });

        // la colonne d'attribut
        addWidget(xid, '${xid}Col0', 'CWColumn',
            <String, dynamic>{iDCount: nbAttr, 'fill': false});
      }
    } else {
      setProp(
          xid,
          ctxLoader.collectionWidget.createEntityByJson(
              'CWForm', <String, dynamic>{
            iDCount: nbAttr,
            'fill': false,
            iDProviderName: provider.id
          }));
    }

    return cwFactory;
  }
}
