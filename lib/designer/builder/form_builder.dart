import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/widget/cw_expand_panel.dart';
import '../../core/data/core_data.dart';
import '../../core/data/core_repository.dart';
import '../application_manager.dart';
import '../designer.dart';

enum ModeForm { column, expand, style, form }

class FormBuilder {
  List<Widget> getFormWidget(
      CWRepository provider, CWAppLoaderCtx ctxLoader, ModeForm mode) {
    var listWidget = <Widget>[];
    CoreDataEntity entity = provider.getEntityByIdx(0);

    CoreDataObjectBuilder? builder =
        ctxLoader.collectionWidget.getClass(entity.type);

    builder ??= ctxLoader.collectionDataModel.getClass(entity.type);

    ctxLoader.factory.disposePath('root');

    AttrFormLoader loader = AttrFormLoader(
        'rootBody0', ctxLoader, builder!.label ?? entity.type, provider, true,
        mode: mode);
    var allAttribut = builder.getAllAttribut();
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

    loader.ctxLoader.addRepository(provider, isEntity: true);

    listWidget.add(loader.getWidget('root', 'root'));
    return listWidget;
  }

  Future<void> createForm(CWWidget widget, CoreDataEntity query) async {
    var app = CWApplication.of();
    // init les data models
    await app.dataModelProvider.getItemsCount(widget.ctx);

    CWRepository provider = app.getRepositoryFromQuery(query, widget);

    provider.getData().idxSelected = 0;
    provider.getData().idxDisplayed = 0;

    _createFormDesign(widget.ctx.loader, provider, widget.ctx.xid,
        widget.ctx.pathWidget, true);

    CoreDesigner.ofView().prepareReBuild();
    CoreDesigner.ofView().reBuild(true);
    widget.repaint();
  }

  void _createFormDesign(CWAppLoaderCtx loaderCtx, CWRepository provider,
      String xid, String path, bool designOnly) {
    final CoreDataObjectBuilder builder =
        loaderCtx.collectionDataModel.getClass(provider.type)!;

    CoreDataEntity entity = provider.getEntityByIdx(0);

    Map<String, dynamic> src = entity.value;

    AttrFormLoader loader = AttrFormLoader(
        xid, loaderCtx, entity.type, provider, !designOnly,
        mode: ModeForm.form);

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
    loader.ctxLoader.addRepository(provider, isEntity: true);

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
      {required this.mode})
      : super(ctxLoader) {
    if (isRoot) {
      if (mode == ModeForm.column) {
        setRoot('root', 'CWColumn');
        tagCol = 'Cont';
      } else {
        setRoot('root', 'CWExpandPanel');
      }
    } else {
      tagCol = 'Cont';
    }
  }

  CWRepository provider;
  int nbAttr = 0;
  String nameForm;
  bool isRoot;
  String tagCol = 'Col0Cont';
  String xid;
  ModeForm mode;

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
        'vstyle': mode == ModeForm.form ? 'border' : 'list',
        '_type_': attribut.type.name.toUpperCase(),
        '@bind': {iDBind: attribut.name, iDProviderName: provider.id}
      });
    }
    nbAttr++;
  }

  @override
  CoreDataEntity initCWFactory() {
    if (isRoot) {
      if (mode == ModeForm.column) {
        setProp(
            'root',
            ctxLoader.collectionWidget.createEntityByJson(
                'CWColumn', <String, dynamic>{iDCount: nbAttr, 'fill': false}));
      } else {
        // gestion properties
        setProp(
            'root',
            ctxLoader.collectionWidget
                .createEntityByJson('CWExpandPanel', <String, dynamic>{
              iDCount: 1,
            }));

        // ajout btn add
        if (mode == ModeForm.style) {
          var action = ctxLoader.collectionWidget.createEntityByJson(
              'CWExpandAction', {
            '_idAction_': 'showStyle@properProvider',
            'icon': Icons.style_rounded
          });

          var constraintTitle = ctxLoader.collectionWidget
              .createEntityByJson('CWExpandConstraint', {
            CWExpandAction.btnHeader.toString(): [action.value]
          });
          setConstraint('rootTitle0', constraintTitle);
        }

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
