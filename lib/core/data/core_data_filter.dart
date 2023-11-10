import '../../designer/application_manager.dart';
import '../widget/cw_core_loader.dart';
import 'core_data.dart';

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