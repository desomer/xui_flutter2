import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/designer/designer.dart';

import '../core/data/core_data_loader.dart';
import '../core/data/core_data_query.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../widget/cw_array.dart';
import '../widget/cw_textfield.dart';

class CoreDataFilter {
  CoreDataFilter() {
    c = CWApplication.of().collection;
    loader = CWApplication.of().loaderData;
  }
  late CoreDataEntity dataFilter;
  late CoreDataCollection c;
  late CWAppLoaderCtx loader;

  void init(String idModel, String name) {
    dataFilter = c.createEntityByJson('DataFilter', {'listGroup': []});
    dataFilter.setAttr(loader, 'model', idModel);
    dataFilter.setAttr(loader, 'name', name);
  }

  CoreDataEntity addGroup(CoreDataEntity parent) {
    CoreDataEntity group = c.createEntityByJson('DataFilterGroup',
        {'operator': 'and', 'listClause': [], 'listGroup': []});
    parent.addMany(loader, 'listGroup', group);
    return group;
  }

  CoreDataEntity addClause(CoreDataEntity group) {
    CoreDataEntity clause = c.createEntityByJson('DataFilterClause',
        {'operator': '=', 'model': dataFilter.getString('model')});
    group.addMany(loader, 'listClause', clause);
    return clause;
  }

  List getListGroup() {
    CoreDataPath? listGroup = dataFilter.getPath(c, 'listGroup');
    return listGroup.value;
  }

  List getListClause(Map<String, dynamic> v) {
    return v['listClause'];
  }

  String getGroupOp(Map<String, dynamic> v) {
    return v['operator'];
  }
}

////////////////////////////////////////////////////////////////////////////////
class WidgetFilterbuilder extends StatefulWidget {
  const WidgetFilterbuilder({required this.filter, super.key});

  final CoreDataFilter filter;

  @override
  State<WidgetFilterbuilder> createState() => _WidgetFilterbuilderState();
}

class _WidgetFilterbuilderState extends State<WidgetFilterbuilder> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String? idModel = CWApplication.of()
        .dataModelProvider
        .getSelectedEntity()
        ?.getString('_id_');

    initFilter(idModel);

    CoreDataCollection c = CWApplication.of().collection;
    CoreDataPath? listGroup = widget.filter.dataFilter.getPath(c, 'listGroup');

    List<Widget> listGroupWidget = [];
    int i = 0;
    // ignore: unused_local_variable
    for (Map<String, dynamic> r in listGroup.value) {
      listGroupWidget.add(WidgetQueryGroup(widget.filter, 'listGroup[$i]', 0));
      i++;
    }

    return Container(
        margin: const EdgeInsets.all(5),
        child: Row(children: [
          Expanded(child: Column(children: listGroupWidget)),
          IconButton(
              onPressed: () {
                refreshData();
              },
              icon: const Icon(Icons.bookmark_add_outlined)),
          IconButton(
              onPressed: () {
                refreshData();
              },
              icon: const Icon(Icons.refresh))
        ]));
  }

  void initFilter(String? idModel) {
    if (idModel != null) {
      CWProvider providerData = CWApplication.of().dataProvider;
      providerData.type = idModel;
      CoreDataLoaderMap dataLoader = providerData.loader as CoreDataLoaderMap;
      dataLoader.setMapID(idModel); // choix de la map a afficher
      if (providerData.loader!.getFilter() == null) {
        widget.filter.init(idModel, 'test');
        var group = widget.filter.addGroup(widget.filter.dataFilter);
        widget.filter.addClause(group);
        providerData.setFilter(widget.filter.dataFilter);
      }
      widget.filter.dataFilter =
          providerData.loader!.getFilter() ?? widget.filter.dataFilter;
    } else {
      widget.filter.init('?', '?');
    }
  }

  void refreshData() {
    CWProvider provider = CWApplication.of().dataProvider;

    String idCache = provider.name + provider.type;
    CoreGlobalCacheResultQuery.cacheNbData.remove(idCache);
    provider.loader!.reload();

    CWApplication.of().loaderData.findWidgetByXid('rootData')!.repaint();
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
                child: Text('Group filter')),
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
      //print("filter ${widget.filter.filter.value}");
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
              // print('f ${pathGroup.getLastEntity().value}');
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
    MaskConfig mask =
        MaskConfig(controller: _controller, focus: aFocus, label: null);

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
        var listAttr = CWApplication.of()
            .dataModelProvider
            .getSelectedEntity()!
            .value['listAttr'];
        attribut =
            c.createEntityByJson('ModelAttributs', listAttr[item.idxCol]);

        var vd = widget.filter.dataFilter.getPath(c, widget.pathFilter);
        vd.getLastEntity().value['colId'] = attribut!.value['_id_'];
        vd.getLastEntity().value['type'] = attribut!.value['type'];
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
    if (colId != null) {
      attribut = CWApplication.of().getCurrentAttributById(colId);
    } else {
      attribut = null;
    }

    String name = attribut?.value['name'] ?? 'Drag column name';

    return Container(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 5, vertical: 1),
        width: 200,
        height: 28,
        child: getDropZone(getBorder(
            attribut == null,
            Text(
                style: TextStyle(
                    color: (attribut?.value['name'] == null
                        ? Colors.white30
                        : Colors.white)),
                name))));
  }
}
