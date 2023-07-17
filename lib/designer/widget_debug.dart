import 'package:flutter/material.dart';
import 'package:flutter_json_viewer/flutter_json_viewer.dart';
import 'package:xui_flutter/designer/widget_tab.dart';

import 'designer.dart';
import 'designer_model.dart';

class WidgetDebug extends StatefulWidget {
  const WidgetDebug({Key? key}) : super(key: key);

  @override
  State<WidgetDebug> createState() => _WidgetDebugState();
}

class _WidgetDebugState extends State<WidgetDebug> {
  @override
  Widget build(BuildContext context) {
    List mdl = [];

    for (var element in DesignerListModel.provider.content) {
      mdl.add(element.value);
    }

    return WidgetTab(heightTab: 40, listTab: [
      Tab(text: "Design"),
      Tab(text: "Model")
    ], listTabCont: [
      Container(
          color: Colors.white,
          child: JsonViewer(CoreDesigner.ofLoader().cwFactory.value)),
      Container(color: Colors.white, child: JsonViewer(mdl)),
    ]);
  }
}
