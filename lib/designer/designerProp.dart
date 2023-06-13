import 'package:flutter/material.dart';

class DesignerPropDart extends StatefulWidget {
  const DesignerPropDart({Key? key}) : super(key: key);

  @override
  State<DesignerPropDart> createState() => DesignerPropDartState();
}

class DesignerPropDartState extends State<DesignerPropDart> {
  List<Widget> listProp = [];

  setProp(List<Widget> list) {
    setState(() {
      listProp = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: listProp);
  }
}
