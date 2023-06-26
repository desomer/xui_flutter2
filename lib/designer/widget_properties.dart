import 'package:flutter/material.dart';

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
    return Column(children: CoreDataSelector.listProp);
  }
}
