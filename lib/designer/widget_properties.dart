import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_widget.dart';
import 'designer.dart';
import 'selector_manager.dart';

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
    return Column(children: CoreDesignerSelector.of().listProp);
  }
}

////////////////////////////////////////////////////////////
class RefreshDesign extends CoreDataAction {
  RefreshDesign(this.aCtx);
  DesignCtx aCtx;

  @override
  execute(CWWidgetCtx ctx, CWWidgetEvent? event) {

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
  execute(CWWidgetCtx ctx, CWWidgetEvent? event) {
    CWWidget? widget = CoreDesigner.of()
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
  execute(CWWidgetCtx ctx, CWWidgetEvent? event) {
    debugPrint("set prop on ${aCtx.xid}");

    aCtx.widget?.ctx.entityForFactory = prop;
    CoreDesigner.of().loader.setProp(aCtx.xid!, prop);
    debugPrint('object  ${CoreDesigner.of().loader.cwFactory}');
  }
}

class MapConstraint extends CoreDataAction {
  DesignCtx aCtx;
  CoreDataEntity prop;

  MapConstraint(this.aCtx, this.prop);

  @override
  execute(CWWidgetCtx ctx, CWWidgetEvent? event) {
    debugPrint("set constraint on ${aCtx.xid}");

    CWWidgetCtx ctxConstraint = CWWidgetCtx(
        aCtx.xid!, CoreDesigner.of().factory, "?", ModeRendering.design);
    ctxConstraint.entityForFactory = prop;
    CoreDesigner.of().factory.mapConstraintByXid[aCtx.xid!] = ctxConstraint;

    // aCtx.widget?.ctx.entityForFactory = prop;
    ctxConstraint.pathDataDesign =
        CoreDesigner.of().loader.setConstraint(aCtx.xid!, prop);
    debugPrint('object  ${CoreDesigner.of().loader.cwFactory}');
  }
}
