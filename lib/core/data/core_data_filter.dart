import '../../designer/application_manager.dart';
import '../widget/cw_core_loader.dart';
import 'core_data.dart';

class CoreDataFilter {
  late CoreDataEntity dataFilter;

  late CoreDataCollection c;

  late CWAppLoaderCtx loader;

  CoreDataFilter() {
    c = CWApplication.of().collection;
    loader = CWApplication.of().loaderData;
  }

  CoreDataEntity addClause(CoreDataEntity group) {
    CoreDataEntity clause = c.createEntityByJson('DataFilterClause',
        {'operator': '=', 'model': dataFilter.getString('model')});
    group.addMany(loader, 'listClause', clause);
    return clause;
  }

  CoreDataEntity addGroup(CoreDataEntity parent) {
    CoreDataEntity group = c.createEntityByJson('DataFilterGroup',
        {'operator': 'and', 'listClause': [], 'listGroup': []});
    parent.addMany(loader, 'listGroup', group);
    return group;
  }

  String getGroupOp(Map<String, dynamic> v) {
    return v['operator'];
  }

  List getListClause(Map<String, dynamic> v) {
    return v['listClause'];
  }

  List getListGroup() {
    CoreDataPath? listGroup = dataFilter.getPath(c, 'listGroup');
    return listGroup.value;
  }

  String getModelID() {
    if (isFilter()) {
      return dataFilter.value['model'];
    } else if (isTable()) {
      return dataFilter.value['_id_'];
    }
    return '?';
  }

  String getQueryKey() {
    StringBuffer buf = StringBuffer();
    List listGroup = getListGroup();
    for (var group in listGroup) {
      List listClause = getListClause(group);
      for (var clause in listClause) {
        var colId = clause['colId'];
        var operator = clause['operator'];
        var value1 = clause['value1'];
        if (colId != null) {
          buf.write('[$colId]$operator[$value1]&');
        }
      }
    }
    return buf.toString();
  }

  void createFilter(String idModel, String name) {
    dataFilter = c.createEntityByJson('DataFilter', {'listGroup': []});
    dataFilter.setAttr(loader, 'model', idModel);
    dataFilter.setAttr(loader, 'name', name);
  }

  void createFilterWithData(Map<String, dynamic> data) {
    dataFilter = c.createEntityByJson('DataFilter', data);
  }

  bool isFilter() {
    String type = dataFilter.value[r'$type'];
    return type == 'DataFilter';
  }

  bool isTable() {
    String type = dataFilter.value[r'$type'];
    return type == 'DataModel';
  }

  void setFilterData(CoreDataEntity entity) {
    dataFilter = entity;
  }
}
