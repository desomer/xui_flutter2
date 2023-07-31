// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter/material.dart';

class WidgetTable extends StatefulWidget {
  const WidgetTable({Key? key}) : super(key: key);

  @override
  State<WidgetTable> createState() => _WidgetTableState();
}

class _WidgetTableState extends State<WidgetTable> {
  // Generate a list of fiction prodcts
  final List<Map> _products = List.generate(30, (i) {
    return {
      "selected": false,
      "id": i,
      "name": "Product $i",
      "price": Random().nextInt(200) + 1
    };
  });

  int _currentSortColumn = 0;
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        child: Row(children : [DataTable(
          border: const TableBorder(
              verticalInside: BorderSide(width: 1, style: BorderStyle.solid)),
          dataRowMaxHeight: 48,
          showCheckboxColumn: true,
          sortColumnIndex: _currentSortColumn,
          sortAscending: _isAscending,
          columnSpacing: 10,
          headingRowColor: MaterialStateProperty.all(Colors.cyan),
          dataRowColor: MaterialStateColor.resolveWith(
              (Set<MaterialState> states) =>
                  states.contains(MaterialState.selected)
                      ? Colors.grey
                      : Colors.black26),
          columns: [
            const DataColumn(numeric: true, label: Text('Id')),
            const DataColumn(label: Text('Name')),
            DataColumn(
                label: const Text(
                  'Price',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                // Sorting function
                onSort: (columnIndex, _) {
                  setState(() {
                    _currentSortColumn = columnIndex;
                    if (_isAscending == true) {
                      _isAscending = false;
                      // sort the product list in Ascending, order by Price
                      _products.sort((productA, productB) =>
                          productB['price'].compareTo(productA['price']));
                    } else {
                      _isAscending = true;
                      // sort the product list in Descending, order by Price
                      _products.sort((productA, productB) =>
                          productA['price'].compareTo(productB['price']));
                    }
                  });
                }),
          ],
          rows: _products.map((item) {
            TextEditingController ctrl = TextEditingController();
            ctrl.text = item['price'].toString();

            return DataRow(
                selected: item['selected'],
                onSelectChanged: (bool? selected) {
                  selected == null
                      ? print('selected is null')
                      : print('select is $selected');

                  item['selected'] = selected;
                  setState(() {});
                },
                cells: [
                  DataCell(
                      SizedBox(width: 200, child: Text(textAlign: TextAlign.right, item['id'].toString()))),
                  DataCell(SizedBox(width: 200, child: Text(item['name']))),
                  DataCell(SizedBox(width: 100, child: TextField(controller: ctrl)))
                ]);
          }).toList(),
        ),
      ])),
    );
  }
}
