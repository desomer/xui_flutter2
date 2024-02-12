import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/designer/designer.dart';

import '../core/data/core_data_filter.dart';
import '../core/data/core_data_query.dart';
import '../core/data/core_repository.dart';
import '../core/store/driver.dart';
import '../core/widget/cw_core_bind.dart';
import '../widget/cw_array.dart';
import '../widget/cw_textfield.dart';

enum FilterBuilderMode { data, query, selector }

////////////////////////////////////////////////////////////////////////////////
// ignore: must_be_immutable
class WidgetFilterbuilder extends StatefulWidget {
  CoreDataFilter? filterDisplayed;
  FilterBuilderMode mode;
  final CWBindWidget? bindWidget;

  WidgetFilterbuilder({required this.mode, super.key, this.bindWidget}) {
    if (bindWidget != null) {
      bindWidget!.fctBindNested = (CoreDataEntity item) {
        if (mode == FilterBuilderMode.data) {
          String? idModel = item.getString('_id_');
          filterDisplayed = getFilterFromCache(idModel);
        }
        if (mode == FilterBuilderMode.query) {
          var aFilter = CoreDataFilter();
          aFilter.createFilterWithData(item.value);
          filterDisplayed = aFilter;
        }
      };
    }
  }

  CoreDataFilter getFilterFromCache(String? idModel) {
    if (idModel != null) {
      CWRepository providerData = CWApplication.of().dataProvider;

      providerData.setLoaderTable(idModel);

      if (providerData.getFilter() == null) {
        var aFilter = CoreDataFilter();
        aFilter.createFilter(idModel, 'preview');
        var group = aFilter.addGroup(aFilter.dataFilter);
        aFilter.addClause(group);
        providerData.setFilter(aFilter);
      }
      providerData.initFilter();
      return providerData.getFilter()!;
    } else {
      return CoreDataFilter()..createFilter('?', '?');
    }
  }

  @override
  State<WidgetFilterbuilder> createState() => _WidgetFilterbuilderState();
}

///////////////////////////////////////////////////////////////////////////////////
class _WidgetFilterbuilderState extends State<WidgetFilterbuilder> {
  @override
  void initState() {
    super.initState();
    widget.bindWidget?.nestedWidgetState = this;
  }

  @override
  Widget build(BuildContext context) {
    widget.bindWidget?.nestedWidgetState = this;
    CoreDataCollection c = CWApplication.of().collection;
    CoreDataPath? listGroup =
        widget.filterDisplayed?.dataFilter.getPath(c, 'listGroup');

    List<Widget> listGroupWidget = [];
    int i = 0;

    for (Map<String, dynamic> r in listGroup?.value ?? []) {
      listGroupWidget.add(WidgetQueryGroup(
          key: ValueKey(r.hashCode),
          widget.filterDisplayed!,
          'listGroup[$i]',
          0));
      i++;
    }

    return Container(
        margin: const EdgeInsets.all(5),
        child: Row(children: [
          Expanded(child: Column(key: GlobalKey(), children: listGroupWidget)),
          Visibility(
              visible: (listGroupWidget.isNotEmpty &&
                  widget.mode == FilterBuilderMode.query),
              child: IconButton(
                  onPressed: () {
                    saveFilter(context);
                  },
                  icon: const Icon(Icons.save))),
          Visibility(
              visible: listGroupWidget.isNotEmpty,
              child: IconButton(
                  onPressed: () {
                    saveNewFilter(context);
                  },
                  icon: const Icon(Icons.bookmark_add))),
          Visibility(
              visible: listGroupWidget.isNotEmpty,
              child: IconButton(
                  onPressed: () async {
                    await saveAndRefreshData();
                  },
                  icon: const Icon(Icons.search_rounded)))
        ]));
  }

  Future<void> saveAndRefreshData() async {
    var app = CWApplication.of();
    await CoreGlobalCache.saveCache(app.dataProvider);
    await CoreGlobalCache.saveCache(app.dataModelProvider);
    Future.delayed(const Duration(milliseconds: 100), () {
      app.refreshData();
    });
  }

  Future<void> saveFilter(BuildContext context) async {
    CWApplication.of()
            .mapFilters[widget.filterDisplayed!.dataFilter.value['_id_']] =
        widget.filterDisplayed!;

    StoreDriver? storage = await StoreDriver.getDefautDriver('main');
    storage!.setData('filters', widget.filterDisplayed!.dataFilter.value);
  }

  Future<void> saveNewFilter(BuildContext context) {
    final ctrl = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save new data filter'),
          content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: 'Filter name',
                // labelStyle: const TextStyle(color: Colors.white70),
              )),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Create'),
              onPressed: () async {
                Navigator.of(context).pop();
                widget.filterDisplayed!.dataFilter.value['name'] = ctrl.text;

                await saveFilter(context);

                CWRepository providerData = CWApplication.of().dataProvider;
                // recharge un filter vide
                providerData.loader!.setFilter(providerData, null);
                setState(() {});
                CWApplication.of().refreshData();
              },
            ),
          ],
        );
      },
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
class WidgetQueryGroup extends StatefulWidget {
  const WidgetQueryGroup(this.filter, this.pathGroup, this.level, {super.key});

  final CoreDataFilter filter;
  final String pathGroup;
  final int level;

  @override
  State<WidgetQueryGroup> createState() => _WidgetQueryGroupState();
}

class _WidgetQueryGroupState extends State<WidgetQueryGroup> {
  List<bool> isSelected = <bool>[true, false];

  Row getGroupWidget(List<Widget> listGroupWidget) {
    return Row(children: [
      Center(
        child: getAndOr(listGroupWidget),
      ),
      Expanded(child: Column(children: listGroupWidget))
    ]);
  }

  Widget getAndOr(List<Widget> listClause) {
    bool isEnable = listClause.length > 2;

    void onPressed(int index) {
      setState(() {
        isSelected[0] = !isSelected[0];
        isSelected[1] = !isSelected[1];
        CoreDataCollection c = CWApplication.of().collection;
        CoreDataPath pathGroup =
            widget.filter.dataFilter.getPath(c, widget.pathGroup);
        pathGroup.getLastEntity().value['operator'] =
            isSelected[0] ? 'and' : 'or';
      });
    }

    return Container(
        height: 30,
        width: 130,
        margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        child: Visibility(
            visible: listClause.length > 1,
            replacement: const Padding(
                padding: EdgeInsets.fromLTRB(5, 5, 0, 0),
                child: Text('Filter clause')),
            child: Row(children: [
              ToggleButtons(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                selectedBorderColor: Colors.white,
                selectedColor: Colors.white,
                fillColor: Colors.deepOrange.shade400,
                isSelected: isSelected,
                onPressed: isEnable ? onPressed : null,
                children: const <Widget>[Text('AND'), Text('OR')],
              ),
              getAddGroupBtn()
            ])));
  }

  Widget getAddGroupBtn() {
    return Tooltip(
        message: 'add group',
        child: InkWell(
          onTap: addGroup,
          child: const Icon(Icons.add_box_outlined),
        ));
  }

  void addGroup() {
    setState(() {
      var c = CWApplication.of().collection;
      var path = widget.filter.dataFilter.getPath(c, widget.pathGroup);
      var group = path.getLastEntity();
      var newGroup = widget.filter.addGroup(group);
      widget.filter.addClause(newGroup);
    });
  }

  @override
  Widget build(BuildContext context) {
    CoreDataCollection c = CWApplication.of().collection;
    CoreDataPath? group = widget.filter.dataFilter.getPath(c, widget.pathGroup);
    List<Widget> listGroupWidget = [];
    List listClause = group.value['listClause'];
    Map<String, dynamic> lastClause = listClause.last;

    if (lastClause['colId'] != null) {
      widget.filter.addClause(widget.filter.dataFilter
          .getPath(c, widget.pathGroup)
          .getLastEntity());
    }

    listClause.removeWhere(
        (clause) => clause['colId'] == null && clause != listClause.last);

    int j = 0;
    for (var clause in listClause) {
      listGroupWidget.add(WidgetQueryClause(
          key: ObjectKey(clause),
          widget.filter,
          '${widget.pathGroup}.listClause[$j]',
          this,
          widget.level,
          j == 0));
      j++;
    }

    j = 0;
    List listGroup = group.value['listGroup'];
    for (var clause in listGroup) {
      listGroupWidget.add(WidgetQueryGroup(
          key: ObjectKey(clause),
          widget.filter,
          '${widget.pathGroup}.listGroup[$j]',
          widget.level + 1));
      j++;
    }

    initGroupOperator(c);

    return Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade700),
            borderRadius: BorderRadius.circular(10)),
        child: getGroupWidget(listGroupWidget));
  }

  void initGroupOperator(CoreDataCollection c) {
    CoreDataPath pathGroup =
        widget.filter.dataFilter.getPath(c, '${widget.pathGroup}.operator');

    if (pathGroup.value == 'or') {
      isSelected[0] = false;
      isSelected[1] = true;
    } else {
      isSelected[0] = true;
      isSelected[1] = false;
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
class WidgetQueryClause extends StatefulWidget {
  const WidgetQueryClause(
      this.filter, this.pathFilter, this.groupState, this.level, this.isFirst,
      {super.key});

  final String pathFilter;
  final CoreDataFilter filter;
  final State<WidgetQueryGroup> groupState;
  final int level;
  final bool isFirst;
  @override
  State<WidgetQueryClause> createState() => _WidgetQueryClauseState();
}

class _WidgetQueryClauseState extends State<WidgetQueryClause> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode aFocus = FocusNode();
  String dropdownvalue = '=';
  late CoreDataPath path;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      path.getLastEntity().value['value1'] = _controller.text;
      print('change filter ${widget.filter.hashCode}');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    aFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var c = CWApplication.of().collection;
    path = widget.filter.dataFilter.getPath(c, widget.pathFilter);
    _controller.text = path.getLastEntity().value['value1'] ?? '';

    bool isEmpty = path.getLastEntity().value['colId'] == null;
    dropdownvalue = path.getLastEntity().value['operator'] ?? '=';

    return Row(
      children: [
        getColumnName(),
        Visibility(visible: !isEmpty, child: getDropdown()),
        Visibility(visible: !isEmpty, child: getValueSimple()),
        Visibility(
            visible: !isEmpty || (widget.level > 0 && widget.isFirst),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                child: getDeleteFilter()))
      ],
    );
  }

  WidgetQuerybuilderColumn getColumnName() {
    return WidgetQuerybuilderColumn(
        key: ObjectKey(path.getLastEntity().value),
        widget.filter,
        '${widget.pathFilter}.colId',
        widget.groupState);
  }

  InkWell getDeleteFilter() {
    return InkWell(
        onTap: () {
          setState(() {
            if (widget.level > 0 &&
                widget.isFirst &&
                path.value['colId'] == null) {
              var c = CWApplication.of().collection;
              var pathGroup =
                  widget.filter.dataFilter.getPath(c, widget.pathFilter);
              pathGroup.entities.removeLast();
              var remove = pathGroup.getLastEntity().value;
              pathGroup.entities.removeLast();
              // print('b ${pathGroup.getLastEntity().value}');
              (pathGroup.getLastEntity().value['listGroup'] as List)
                  .remove(remove);

              CoreDesigner.of().dataFilterKey.currentState?.setState(() {});
            } else {
              (path.value as Map).remove('colId');
              (path.value as Map).remove('value1');
              widget.groupState.setState(() {});
            }
          });
        },
        child: const Icon(size: 20, Icons.cancel_outlined));
  }

  // List of items in our dropdown menu
  var items = [
    '=',
    '<',
    '>',
    '>=',
    '<=',
    'like',
    'ilike',
    'is one of',
    'is check'
  ];

  Widget getDropdown() {
    return DecoratedBox(
        decoration: BoxDecoration(
            color: Colors
                .deepOrange.shade400, //background color of dropdown button
            border: Border.all(
                color: Colors.black38, width: 3), //border of dropdown button
            borderRadius:
                BorderRadius.circular(50), //border raiuds of dropdown button
            boxShadow: const <BoxShadow>[
              //apply shadow on Dropdown button
              BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.57), //shadow for button
                  blurRadius: 5) //blur radius of shadow
            ]),
        child: Padding(
            padding: const EdgeInsets.only(left: 30, right: 0),
            child: DropdownButton(
              // Initial Value
              value: dropdownvalue,
              underline: Container(), //remove underline
              isDense: true,

              // Down Arrow Icon
              icon: const Icon(Icons.keyboard_arrow_down),

              // Array list of items
              items: items.map((String items) {
                return DropdownMenuItem(
                  value: items,
                  child: Text(items),
                );
              }).toList(),
              // After selecting the desired option,it will
              // change button value to selected value
              onChanged: (String? newValue) {
                setState(() {
                  dropdownvalue = newValue!;
                  path.getLastEntity().value['operator'] = dropdownvalue;
                });
              },
            )));
  }

  Widget getValueSimple() {
    MaskConfig mask = MaskConfig(
        bindType: 'TEXT',
        visualType: 'list',
        inArray: true,
        controller: _controller,
        focus: aFocus,
        label: null);

    return Padding(
        padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
        child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 5, vertical: 1),
            height: 28,
            width: 200,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: mask.getTextfield()));
  }
}

////////////////////////////////////////////////////////////////////////////////
class WidgetQuerybuilderColumn extends StatefulWidget {
  const WidgetQuerybuilderColumn(this.filter, this.pathFilter, this.groupState,
      {super.key});

  final String pathFilter;
  final CoreDataFilter filter;
  final State<WidgetQueryGroup> groupState;

  @override
  State<WidgetQuerybuilderColumn> createState() =>
      _WidgetQuerybuilderColumnState();
}

class _WidgetQuerybuilderColumnState extends State<WidgetQuerybuilderColumn> {
  CoreDataEntity? attribut;

  @override
  void initState() {
    super.initState();
  }

  Widget getDropZone(Widget child) {
    return DragTarget<DragColCtx>(
        builder: (context, candidateItems, rejectedItems) {
      return AnimatedScale(
          scale: candidateItems.isEmpty ? 1 : 0.95,
          duration: const Duration(milliseconds: 100),
          child: child);
    }, onWillAccept: (item) {
      return true;
    }, onAccept: (item) {
      setState(() {
        var c = CWApplication.of().collection;
        var tableEntity =
            CWApplication.of().getTableEntityByID(widget.filter.getModelID());
        List listAttr = tableEntity.value['listAttr'];

        if (listAttr.length <= item.idxCol) {
          // gestion de _id_, _created_, etc...
          var listAttribut = CWApplication.of()
              .getTableAllAttrByID(widget.filter.getModelID());
          attribut = c.createEntityByJson('ModelAttributs', {
            '_id_': listAttribut[item.idxCol].name,
            'name': listAttribut[item.idxCol].name,
            'type': 'Text'
          });
        } else {
          attribut =
              c.createEntityByJson('ModelAttributs', listAttr[item.idxCol]);
        }

        var vd = widget.filter.dataFilter.getPath(c, widget.pathFilter);
        vd.getLastEntity().value['colId'] = attribut!.value['_id_'];
        vd.getLastEntity().value['typeCol'] = attribut!.value['type'];
      });
      widget.groupState.setState(() {});
    });
  }

  Widget getBorder(bool isEmpty, Widget child) {
    return isEmpty
        ? DottedBorder(
            color: Colors.grey,
            dashPattern: const <double>[6, 6],
            strokeWidth: 1,
            child: SafeArea(minimum: const EdgeInsets.all(0), child: child))
        : Container(
            decoration:
                BoxDecoration(border: Border.all(width: 1, color: Colors.grey)),
            child: SafeArea(minimum: const EdgeInsets.all(1), child: child));
  }

  @override
  Widget build(BuildContext context) {
    var c = CWApplication.of().collection;
    var vd = widget.filter.dataFilter.getPath(c, widget.pathFilter);
    String? colId = vd.getLastEntity().value['colId'];
    String idTable = widget.filter.getModelID();

    String name = 'Drag column name';
    bool isEmpty = true;
    if (colId != null) {
      attribut = CWApplication.of().getAttributById(idTable, colId);
      if (attribut == null) {
        name = colId;
      } else {
        name = attribut?.value['name'];
      }
      isEmpty = false;
    } else {
      attribut = null;
    }

    return Container(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 5, vertical: 1),
        width: 200,
        height: 28,
        child: getDropZone(getBorder(
            isEmpty,
            Text(
                style: TextStyle(
                    color: (isEmpty
                        ? Colors.white30
                        : Colors.white)),
                name))));
  }
}
