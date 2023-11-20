import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/application_manager.dart';

import '../core/data/core_data.dart';
import '../core/data/core_data_query.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import '../widget/cw_expand_panel.dart';
import 'builder/form_builder.dart';
import 'widget/widget_tab.dart';

class DesignerModelAttribut extends StatelessWidget {
  const DesignerModelAttribut({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetTab tabAttributDesc = WidgetTab(heightTab: 30, listTab: const [
      Tab(text: 'Properties'),
      Tab(text: 'Validator'),
      Tab(text: 'Style')
    ], listTabCont: [
      Row(
        children: [const Expanded(child: DesignerAttribut()), getRainbox()],
      ),
      Container(),
      Container()
    ]);
    return tabAttributDesc;
  }

  Widget getRainbox()
  {
     return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            offset: Offset(-20, 20),
            color: Colors.red,
            blurRadius: 15,
            spreadRadius: -10,
          ),
          BoxShadow(
            offset: Offset(-20, -20),
            color: Colors.orange,
            blurRadius: 15,
            spreadRadius: -10,
          ),
          BoxShadow(
            offset: Offset(20, -20),
            color: Colors.blue,
            blurRadius: 15,
            spreadRadius: -10,
          ),
          BoxShadow(
            offset: Offset(25, 25),
            color: Colors.deepPurple,
            blurRadius: 15,
            spreadRadius: -10,
          )
        ],
        //color: Colors.grey.shade800
      ),
      child: Card(
        color: Colors.grey.shade800,
        elevation: 3,
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////
class DesignerAttribut extends StatefulWidget {
  const DesignerAttribut({super.key});

  @override
  State<DesignerAttribut> createState() => _DesignerAttributState();
}

class _DesignerAttributState extends State<DesignerAttribut> {
  @override
  Widget build(BuildContext context) {
    CWAppLoaderCtx loader =
        CWAppLoaderCtx().from(CWApplication.of().loaderModel);

    var provider = CWProvider(
        'AttrProvider', 'DataAttribut', CWProviderDataSelector.noLoader())
      ..addContent(
          loader.collectionDataModel.createEntityByJson('DataAttribut', {}));

    provider.header = loader.collectionDataModel
        .createEntityByJson('DataHeader', {'label': 'Attribut'});

    void deleteAttr(CWWidgetEvent e) async {
      var attrEntity =
          CWApplication.of().dataAttributProvider.getSelectedEntity()!;
      // print(attrEntity!.value);
      attrEntity.operation = CDAction.delete;
      CoreGlobalCache.saveCache(CWApplication.of().dataAttributProvider);
      CoreGlobalCache.saveCache(CWApplication.of().dataModelProvider);
      CWApplication.of().dataAttributProvider.doEvent(
          CWProviderAction.onStateDelete, CWApplication.of().loaderModel,
          repaintXid: 'rootAttrExp');

      //TODO supprimer la colonne de le bdd
    }

    provider.addUserAction('deleteAttr', CoreDataActionFunction(deleteAttr));

    var c = loader.collectionWidget;
    loader.addConstraint('rootTitle0', 'CWExpandConstraint').addMany(
        loader,
        CWExpandAction.actions.toString(),
        c.createEntityByJson('CWExpandAction', {
          '_idAction_': 'deleteAttr@AttrProvider',
          'label': 'Delete attribut',
          'icon': Icons.delete_forever
        }));

    return Row(children: [
      SizedBox(
          width: 300,
          child:
              Column(children: FormBuilder().getFormWidget(provider, loader)))
    ]);
  }
}
