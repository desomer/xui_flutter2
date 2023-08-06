import 'package:localstorage/localstorage.dart';

class StoreDriver {
  dynamic getAllData(String idTable) async {}
  setData(String idTable, Map<String, dynamic> json) async {}
  deleteTable(String idTable) async {}
}

class LocalstorageDriver extends StoreDriver {
  @override
  dynamic getAllData(String idTable) async {
    LocalStorage storage = LocalStorage('$idTable.json');
    await storage.ready;
    await Future.delayed(const Duration(seconds: 1));
    return storage.getItem('data');
  }

  @override
  setData(String idTable, Map<String, dynamic> json) async {
    LocalStorage storage = LocalStorage('$idTable.json');
    storage.setItem('data', json);
  }

  @override
  deleteTable(String idTable) async {
    LocalStorage storage = LocalStorage('$idTable.json');
    await storage.ready;
    storage.clear();
  }
}
