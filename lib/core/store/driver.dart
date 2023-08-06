// import 'package:xui_flutter/core/store/nosql/localstorage.dart';
import 'package:xui_flutter/core/store/sql/supabased.dart';

class StoreDriver {
  static SupabaseDriver? supra;

  dynamic getAllData(String idTable) async {}
  setData(String idTable, Map<String, dynamic> data) async {}
  deleteData(String idTable, List data) async {}
  deleteTable(String idTable) async {}

  static Future<StoreDriver>? getDefautDriver(String id) async {
    if (supra == null) {
      supra = SupabaseDriver();
      await supra!.init();
    }
    return supra!;
  }
}
