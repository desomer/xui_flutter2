import 'package:localstorage/localstorage.dart';

import '../driver.dart';


class LocalstorageDriver extends StoreDriver {
  @override
  dynamic getAllData(String idTable) async {
    LocalStorage storage = LocalStorage('$idTable.json');
    await storage.ready;
    await Future.delayed(const Duration(seconds: 1));
    return storage.getItem('data');
  }

  @override
  setData(String idTable, Map<String, dynamic> data) async {
    LocalStorage storage = LocalStorage('$idTable.json');
    storage.setItem('data', data);
  }

  @override
  deleteTable(String idTable) async {
    LocalStorage storage = LocalStorage('$idTable.json');
    await storage.ready;
    storage.clear();
  }
}
