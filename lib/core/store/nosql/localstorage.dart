import 'package:localstorage/localstorage.dart';

import '../../data/core_data.dart';
import '../driver.dart';

class LocalstorageDriver extends StoreDriver {
  @override
  dynamic getJsonData(String idTable, CoreDataEntity? filters) async {
    LocalStorage storage = LocalStorage('$idTable.json');
    await storage.ready;
    await Future.delayed(const Duration(seconds: 1));
    return storage.getItem('data');
  }

  @override
  Future setData(String idTable, Map<String, dynamic> data) async {
    LocalStorage storage = LocalStorage('$idTable.json');
    storage.setItem('data', data);
  }

  @override
  Future deleteTable(String idTable) async {
    LocalStorage storage = LocalStorage('$idTable.json');
    await storage.ready;
    storage.clear();
  }
}
