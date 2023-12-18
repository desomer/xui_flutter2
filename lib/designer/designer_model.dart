import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/designer/builder/array_builder.dart';
import 'package:xui_flutter/designer/widget_crud.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_bind.dart';

//////////////////////////////////////////////////////////////////////////////////

class DesignerModel extends StatelessWidget {
  const DesignerModel({required this.bindWidget, super.key});

  final CWBindWidget bindWidget;

  @override
  Widget build(BuildContext context) {
    //print('bind id ${bindWidget.id}');

    var app=CWApplication.of();

    if (bindWidget.id == 'bindModel2Attr') {
      bindWidget.fctBindNested = (selected) {
        bindWidget.nestedWidgetState = CWApplication.of()
            .loaderModel
            .findWidgetByXid('rootAttrExp')
            ?.ctx
            .state;
      };
    } else if (bindWidget.id == 'bindProvider2Attr') {
      bindWidget.fctBindNested = (selected) {
        var selectedEntity = bindWidget.currentEntity;
        if (selectedEntity != null) {
          var name = selectedEntity.value['name'] ?? '?';
          app.listAttrProvider.header!.value['label'] = name;
          app.loaderModel.findByXid('rootAttr2Title0')!.changeProp('label', name);
        }

        bindWidget.nestedWidgetState = 
            app.loaderModel
            .findWidgetByXid('rootAttr2Exp')
            ?.ctx
            .state;
      };
    }

    return Container(
      color: Colors.black26,
      child: Stack(
        children: [
          Positioned(
              left: 20,
              top: 20,
              width: 300,
              child: Container(
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: DesignerListAttribut(bindWidget: bindWidget)))
        ],
      ),
    );
  }
}

/// le model (liste des attributs)
class DesignerListAttribut extends StatefulWidget {
  const DesignerListAttribut({required this.bindWidget, super.key});
  final CWBindWidget bindWidget;

  @override
  State<DesignerListAttribut> createState() => _DesignerListAttributState();
}

class _DesignerListAttributState extends State<DesignerListAttribut> {
  ArrayBuilder? arrayBuilder;

  @override
  void initState() {
    super.initState();
    var app = CWApplication.of();

    if (widget.bindWidget.id == 'bindModel2Attr') {
      arrayBuilder = ArrayBuilder(
          loaderCtx: app.loaderModel, provider: app.dataAttributProvider);

      var selectedEntity = app.dataModelProvider.getSelectedEntity();
      if (selectedEntity != null) {
        var name = selectedEntity.value['name'] ?? '?';
        app.dataAttributProvider.header!.value['label'] = name;
      }
      arrayBuilder!.initDesignArrayFromLoader('rootAttr', 'ReorderList');
    } else if (widget.bindWidget.id == 'bindProvider2Attr') {
      arrayBuilder = ArrayBuilder(
          loaderCtx: app.loaderModel, provider: app.listAttrProvider);

      arrayBuilder!.initDesignArrayFromLoader('rootAttr2', 'List');
    }
  }

  @override
  Widget build(BuildContext context) {
    var app = CWApplication.of();

    return LayoutBuilder(builder: (context, constraints) {
      List<Widget> listModel =
          arrayBuilder!.getArrayWithConstraint(constraints: constraints);
      if (widget.bindWidget.id == 'bindModel2Attr') {
        listModel.add(WidgetDrag(provider: app.dataAttributProvider));
      }
      return Column(children: listModel);
    });
  }
}

class OnAddAttr extends CoreDataAction {
  OnAddAttr(this.provider);
  CWProvider provider;

  @override
  void execute(Object? ctx, CWWidgetEvent? event) {
    // ajout d'un nouveau attribut au model
    CoreDataEntity entity = CWApplication.of().collection.createEntityByJson(
        'ModelAttributs',
        {'name': '?', 'type': event!.payload!.toString().toUpperCase()});

    CWApplication.of().dataAttributProvider.loader!.addData(entity);
    CWApplication.of().bindModel2Attr.repaint();
  }
}

class OnBuildEdit extends CoreDataAction {
  OnBuildEdit(this.editName, this.displayPrivate);
  List<String> editName;
  bool displayPrivate;

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CoreDataAttribut attr = event!.payload['attr'];
    Map<String, dynamic> infoAttr = event.payload['infoAttr'];

    if (attr.name.startsWith('_')) {
      if (!displayPrivate) {
        event.retAction = 'None';
      }
      return;
    }

    for (var element in editName) {
      if (element == attr.name || element == '*') {
        event.ret = event.loader!.collectionWidget.createEntityByJson(
            'CWTextfield', {'withLabel': false, 'type': infoAttr['type']});
        return;
      }
    }
  }
}
