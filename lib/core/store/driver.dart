// import 'package:xui_flutter/core/store/nosql/localstorage.dart';
import 'package:xui_flutter/core/store/sql/supabased.dart';

import '../data/core_data.dart';

class StoreDriver {
  static SupabaseDriver? supra;

  dynamic getJsonData(String idTable, CoreDataEntity? filters) async {}
  Future setData(String idTable, Map<String, dynamic> data) async {}
  Future deleteData(String idTable, List data) async {}
  Future deleteTable(String idTable) async {}

  static Future<StoreDriver>? getDefautDriver(String id) async {
    if (supra == null) {
      supra = SupabaseDriver();
      await supra!.init();
    }
    return supra!;
  }
}
