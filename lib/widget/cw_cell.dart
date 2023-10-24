import 'package:flutter/material.dart';


// Affiche un erreur sur la cellule (ex:date)


// ignore: must_be_immutable
class CWCellIndicator extends StatefulWidget {
  CWCellIndicator({super.key});
  String? message;
  Color? color;
  @override
  State<CWCellIndicator> createState() => _CWCellIndicatorState();
}

class _CWCellIndicatorState extends State<CWCellIndicator> {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
        message: widget.message??'',
        child: Container(
          width: 8,
          color: widget.color,
        ));
  }
}
