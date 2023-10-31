import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';

class WidgetDragTarget extends StatefulWidget {
  const WidgetDragTarget({super.key});

  @override
  State<WidgetDragTarget> createState() => _WidgetDragTargetState();
}

class _WidgetDragTargetState extends State<WidgetDragTarget> {
  final List<XFile> _list = [];

  bool _dragging = false;

  Offset? offset;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        setState(() {
          _list.addAll(detail.files);
        });

        debugPrint('onDragDone:');
        for (final file in detail.files) {
          debugPrint('  ${file.path} ${file.name}'
              '  ${await file.lastModified()}'
              '  ${await file.length()}'
              '  ${file.mimeType}');

          var bytes = await file.readAsBytes();
          var excel = Excel.decodeBytes(bytes);

          for (var table in excel.tables.keys) {
            debugPrint(table); //sheet Name
            debugPrint(excel.tables[table]!.maxColumns.toString());
            debugPrint(excel.tables[table]!.maxRows.toString());
            for (var row in excel.tables[table]!.rows) {
              debugPrint('${row[0]!.value}');
            }
          }
        }
      },
      onDragUpdated: (details) {
        setState(() {
          offset = details.localPosition;
        });
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
          offset = detail.localPosition;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
          offset = null;
        });
      },
      child: Container(
        height: 200,
        width: 200,
        color: _dragging ? Colors.blue.withOpacity(0.4) : Colors.black26,
        child: Stack(
          children: [
            if (_list.isEmpty)
              const Center(child: Text('Drop here'))
            else
              Text(_list.map((e) => e.path).join('\n')),
            if (offset != null)
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  '$offset',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
          ],
        ),
      ),
    );
  }
}
