import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/designer/selector_manager.dart';
import 'package:xui_flutter/widget/cw_textfield.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import 'designer.dart';
import 'builder/prop_builder.dart';
import 'designer_model.dart';
import 'designer_selector_provider.dart';

// ignore: must_be_immutable
class DesignerProp extends StatefulWidget {
  DesignerProp({super.key});
  List<Widget> listProp = [];
  @override
  State<DesignerProp> createState() => DesignerPropState();
}

class DesignerPropState extends State<DesignerProp> {
  @override
  Widget build(BuildContext context) {
    return Column(children: CoreDesignerSelector.of().propBuilder.listProp);
  }
}

////////////////////////////////////////////////////////////
class OnMount extends CoreDataAction {
  OnMount(this.aCtx, this.path);
  DesignCtx aCtx;
  String path;

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    if (ctx!.designEntity!.type == 'CWTextfield') {
      String attr = ctx.designEntity!.value[iDBind];
      CWTextfield wid = event!.payload! as CWTextfield;
      debugPrint('--- OnMount ----->  $attr on $path = $wid');
    }
  }
}

class OnWidgetSelect extends CoreDataAction {
  OnWidgetSelect(this.aCtx, this.path);
  DesignCtx aCtx;
  String path;

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CoreDesigner.emit(CDDesignEvent.select, aCtx.widget!.ctx.getSlot()!.ctx);
  }
}

class OnLinkSelect extends CoreDataAction {
  OnLinkSelect(this.aCtx, this.path);
  DesignCtx aCtx;
  String path;

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    print('link');
    //CoreDataAttribut attr = ctx!.designEntity?.value['_attr_'];
    selectAttr(event!.buildContext!);
  }

  Future<void> selectAttr(BuildContext context) {
    CWWidgetCtx ctxQuery = CWWidgetCtx('', CWApplication.of().loaderModel, '');
    ctxQuery.designEntity = CWApplication.of()
        .loaderModel
        .collectionWidget
        .createEntityByJson('CWArray', {iDProviderName: 'DataModelProvider'});

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('select attribut'),
          content: Row(children: [
            Container(
              decoration: BoxDecoration(border: Border.all()),
              height: 500,
              width: 300,
              child: DesignerProvider(
                  ctx: ctxQuery,
                  bindWidget: CWApplication.of().bindProvider2Attr),
            ),
            Container(
              decoration: BoxDecoration(border: Border.all()),
              height: 500,
              width: 500,
              child: DesignerModel(bindWidget: CWApplication.of().bindProvider2Attr),
            ),
          ]),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Bind'),
              onPressed: () async {},
            ),
          ],
        );
      },
    );
  }
}

class RefreshDesign extends CoreDataAction {
  RefreshDesign(this.aCtx);
  DesignCtx aCtx;

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    aCtx.widget!.repaint();

    Future.delayed(const Duration(milliseconds: 100), () {
      CoreDesigner.emit(CDDesignEvent.reselect, null);
    });
  }
}

class RefreshDesignParent extends CoreDataAction {
  RefreshDesignParent(this.aCtx);
  DesignCtx aCtx;

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CWWidget? widget = CoreDesigner.ofView()
        .getWidgetByPath(CWWidgetCtx.getParentPathFrom(aCtx.pathWidget));
    widget?.repaint();

    Future.delayed(const Duration(milliseconds: 100), () {
      CoreDesigner.emit(CDDesignEvent.reselect, null);
    });
  }
}

class MapDesign extends CoreDataAction {
  DesignCtx aCtx;
  CoreDataEntity prop;

  MapDesign(this.aCtx, this.prop);

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    debugPrint('set prop on ${aCtx.xid}');

    PropBuilder.setDesignOn(aCtx, prop);
  }
}

class MapConstraint extends CoreDataAction {
  DesignCtx aCtx;
  CoreDataEntity prop;

  MapConstraint(this.aCtx, this.prop);

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    debugPrint('set constraint on ${aCtx.xid}');

    // CWWidgetCtx ctxConstraint =
    //     CWWidgetCtx(aCtx.xid!, CoreDesigner.ofLoader().ctxLoader, "?");
    // ctxConstraint.designEntity = prop;
    // CoreDesigner.ofFactory().mapConstraintByXid[aCtx.xid!] = ctxConstraint;

    // // aCtx.widget?.ctx.entityForFactory = prop;
    // ctxConstraint.pathDataDesign = CoreDesigner.ofLoader()
    //     .setConstraint(aCtx.xid!, prop, path: ctxConstraint.pathDataDesign);

    PropBuilder.setDesignOn(aCtx, prop);

    debugPrint('MapConstraint  ${CoreDesigner.ofLoader().cwFactory}');
  }
}
