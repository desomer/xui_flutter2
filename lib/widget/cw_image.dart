import 'package:flutter/material.dart';

class CwImage extends StatefulWidget {
  CwImage({super.key});

  @override
  CwImageState createState() => CwImageState();
}

class CwImageState extends State<CwImage> {
  static Widget? wi;

  @override
  Widget build(BuildContext context) {
    return wi ?? Text('vide');
  }
}
