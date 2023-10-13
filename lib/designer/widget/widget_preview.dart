import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/designer.dart';

class WidgetPreview extends StatefulWidget {
  const WidgetPreview({Key? key}) : super(key: key);

  @override
  State<WidgetPreview> createState() => _WidgetPreviewState();
}

class _WidgetPreviewState extends State<WidgetPreview> {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 50,
        margin: const EdgeInsets.all(0),
        padding: const EdgeInsets.all(10),
        child: ToggleButtons(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          selectedBorderColor: Colors.white,
          selectedColor: Colors.white,
          fillColor: Colors.deepOrange.shade400,
          isSelected: isSelected,
          onPressed: onPressed,
          children: const <Widget>[
            Icon(Icons.draw_rounded),
            Icon(Icons.preview_rounded)
          ],
        ));
  }

  List<bool> isSelected = <bool>[true, false];
  void onPressed(int index) {
    setState(() {
      isSelected[0] = !isSelected[0];
      isSelected[1] = !isSelected[1];
      CoreDesigner.emit(CDDesignEvent.preview, isSelected[1]);
    });
  }
}
