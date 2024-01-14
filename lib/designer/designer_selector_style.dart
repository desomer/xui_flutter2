import 'package:flutter/material.dart';

import 'selector_manager.dart';

// ignore: must_be_immutable
class DesignerStyle extends StatefulWidget {
  DesignerStyle({super.key});
  List<Widget> listProp = [];

  @override
  State<DesignerStyle> createState() => DesignerStyleState();
}

class DesignerStyleState extends State<DesignerStyle> {
  @override
  Widget build(BuildContext context) {
    return Column(children: CoreDesignerSelector.of().styleBuilder.listStyle);
  }
}