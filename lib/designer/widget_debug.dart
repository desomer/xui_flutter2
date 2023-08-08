import 'package:flutter/material.dart';
import 'package:flutter_json_viewer/flutter_json_viewer.dart';
import 'package:xui_flutter/designer/widget_tab.dart';

import 'application_manager.dart';
import 'designer.dart';

class WidgetDebug extends StatefulWidget {
  const WidgetDebug({Key? key}) : super(key: key);

  @override
  State<WidgetDebug> createState() => _WidgetDebugState();
}

class _WidgetDebugState extends State<WidgetDebug> {
  @override
  Widget build(BuildContext context) {
    List mdl = [];

    for (var element in CWApplication.of().dataModelProvider.content) {
      mdl.add(element.value);
    }

    Map<String, dynamic> data = {};

    for (var element in CWApplication.of().cacheMapData.entries) {
      data[element.key] = element.value.value;
    }

    return WidgetTab(heightTab: 40, listTab: const [
      Tab(text: "Design"),
      Tab(text: "Model"),
      Tab(text: "Data")
    ], listTabCont: [
      Container(
          color: Colors.white,
          child: JsonViewer(CoreDesigner.ofLoader().cwFactory.value)),
      Container(color: Colors.white, child: JsonViewer(mdl)),
      Container(color: Colors.white, child: JsonViewer(data)),
    ]);
  }
}
