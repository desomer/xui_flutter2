import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CWCellIndicator extends StatefulWidget {
  CWCellIndicator({Key? key}) : super(key: key);
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
