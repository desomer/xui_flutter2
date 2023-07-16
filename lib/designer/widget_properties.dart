import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/selector_manager.dart';
import 'package:xui_flutter/widget/cw_textfield.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import 'designer.dart';
import 'prop_builder.dart';

// ignore: must_be_immutable
class DesignerProp extends StatefulWidget {
  DesignerProp({Key? key}) : super(key: key);
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
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    if (ctx!.designEntity!.type == "CWTextfield") {
      String attr = ctx.designEntity!.value["bind"];
      CWTextfield wid = event!.payload! as CWTextfield;
      print('--- OnMount ----->  $attr on $path = $wid');
    }
  }
}

class RefreshDesign extends CoreDataAction {
  RefreshDesign(this.aCtx);
  DesignCtx aCtx;

  @override
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
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
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
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
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    debugPrint("set prop on ${aCtx.xid}");

    PropBuilder.setDesignOn(aCtx, prop);
  }
}

class MapConstraint extends CoreDataAction {
  DesignCtx aCtx;
  CoreDataEntity prop;

  MapConstraint(this.aCtx, this.prop);

  @override
  execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    debugPrint("set constraint on ${aCtx.xid}");

    CWWidgetCtx ctxConstraint = CWWidgetCtx(
        aCtx.xid!, CoreDesigner.ofLoader().ctxLoader, "?");
    ctxConstraint.designEntity = prop;
    CoreDesigner.ofFactory().mapConstraintByXid[aCtx.xid!] = ctxConstraint;

    // aCtx.widget?.ctx.entityForFactory = prop;
    ctxConstraint.pathDataDesign =
        CoreDesigner.ofLoader().setConstraint(aCtx.xid!, prop);
    debugPrint('object  ${CoreDesigner.ofLoader().cwFactory}');
  }
}
