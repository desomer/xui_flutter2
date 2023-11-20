import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/core_data.dart';
import '../../data/core_data_filter.dart';
import '../driver.dart';

// postgre _r$y-74WSMFKk8

class SupabaseDriver extends StoreDriver {
  Map<String, SupabaseClient> client = {};
  String idCustomer = 'demo';
  String idNamespace = 'demo';

  static final Map<String, String> _mapOpe = {
    '=': 'eq',
    '>': 'gt',
    '>=': 'gte',
    '<': 'lt',
    '<=': 'lte',
    'like': 'like',
    'ilike': 'ilike'
  };

  Future<void> init() async {
    try {
      await Supabase.initialize(
        url: 'https://pkrutsmghgjxapkozcyn.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBrcnV0c21naGdqeGFwa296Y3luIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTEyNzI4MjgsImV4cCI6MjAwNjg0ODgyOH0.nlADIUSTgwWCZ9Q2vUgr6iwPHBZwxSjLlQKCV_zdt8I',
      );

      // It's handy to then extract the Supabase client in a variable for later uses
      client['main'] = Supabase.instance.client;

      AuthResponse res = await client['main']!.auth.signInWithPassword(
            email: 'gauthier.desomer@gmail.com',
            password: 'Charley.30',
          );
      // ignore: unused_local_variable
      final Session? session = res.session;
      // ignore: unused_local_variable
      final User? user = res.user;
    } on Exception catch (e) {
      debugPrint('Exception catch $e');
    }

    // Listen to auth state changes
    // supabase.auth.onAuthStateChange.listen((data) {
    //   final AuthChangeEvent event = data.event;
    //   final Session? session = data.session;
    //   // Do something when there is an auth event
    // });

    // await supabase.from('ListModel').insert({
    //   "json": {"ok": "good"}
    // });
    // final data = await supabase.from('ListModel').select('json');
    // debugPrint(data.toString());

    //testBucket();
  }

  @override
  dynamic getJsonData(String idTable, CoreDataEntity? filters) async {
    if (idTable == '#pages') {
      return await _getJsonPages();
    } else {
      return await _getJsonDataModel(idTable, filters);
    }
  }

  Future<dynamic> _getJsonPages() async {
    var query = client['main']!
        .from('ListApp')
        .select('json')
        .eq('idData', 'Home')
        .eq('idCustomer', idCustomer)
        .eq('idNamespace', idNamespace);

    var ret = await query;
    var result = [];
    if (ret is List) {
      if (ret.isNotEmpty) {
        for (var r in ret) {
          result.add(r['json']);
        }
      } else {
        return null;
      }
    }
    return result[0];
  }

  dynamic _getJsonDataModel(String idTable, CoreDataEntity? filters) async {
    var query = client['main']!
            .from('ListModel')
            .select('json')
            .eq('idTable', idTable)
            .eq('idCustomer', idCustomer)
            .eq('idNamespace', idNamespace)
        // .appendSearchParams(key, value)
        //.or(filters)
        ;

    if (filters != null) {
      CoreDataFilter f = CoreDataFilter();
      f.dataFilter = filters;
      List listGroup = f.getListGroup();
      for (var group in listGroup) {
        //var op = f.getGroupOp(group);
        List listClause = f.getListClause(group);
        for (var clause in listClause) {
          var colId = clause['colId'];
          var operator = clause['operator'];
          var value1 = clause['value1'];
          if (colId != null) {
            query.filter('json->>$colId', _mapOpe[operator]!, value1);
          }
        }
      }
    }

    try {
      var ret = await query;

      if (ret is List) {
        if (ret.isNotEmpty) {
          var result = [];
          for (var r in ret) {
            result.add(r['json']);
          }
          return {
            r'$type': 'DataContainer',
            'idData': idTable,
            'listData': result
          };
        }
      }
    } on Exception catch (e) {
      debugPrint('Exception $e');
    }
    return null;
  }

  @override
  Future setData(String idTable, Map<String, dynamic> data) async {
    if (idTable == '#pages') {
      await client['main']!.from('ListApp').upsert([
        {
          'idCustomer': idCustomer,
          'idNamespace': idNamespace,
          'idData': 'Home',
          'json': data
        }
      ]);
    } else if (idTable == 'filters') {
      await client['main']!.from('ListModel').upsert([
        {
          'idTable': 'filters',
          'idCustomer': idCustomer,
          'idNamespace': idNamespace,
          'idData': '${data['_id_']}',
          'json': data
        }
      ]);
    } else if (data[CoreDataEntity.cstTypeAttr] == 'DataContainer') {
      // save data & model
      for (var element in data['listData']) {
        if (element['_operation_'] == CDAction.create.index ||
            element['_operation_'] == CDAction.update.index) {
          element['_operation_'] = CDAction.read.index;
          await client['main']!.from('ListModel').upsert([
            {
              'idTable': idTable,
              'idCustomer': idCustomer,
              'idNamespace': idNamespace,
              'idData': element['_id_'],
              'json': element // json.encode(element)
            }
          ]); //.select('json').eq("idTable", idTable);
        }
      }
    } else {}
  }

  @override
  Future deleteTable(String idTable) async {
    await client['main']!
        .from('ListModel')
        .delete()
        .eq('idTable', idTable)
        .eq('idCustomer', idCustomer)
        .eq('idNamespace', idNamespace);

    debugPrint('delete table $idTable');
  }

  @override
  Future deleteData(String idTable, List data) async {
    if (idTable == '#pages') {
      await client['main']!
          .from('ListApp')
          .delete()
          .eq('idCustomer', idCustomer)
          .eq('idNamespace', idNamespace)
          .eq('idData', 'Home');
      debugPrint('delete row app');
    } else {
      for (var element in data) {
        await client['main']!
            .from('ListModel')
            .delete()
            .eq('idTable', idTable)
            .eq('idCustomer', idCustomer)
            .eq('idNamespace', idNamespace)
            .eq('idData', element['_id_']);
        debugPrint('delete row $idTable $element');
      }
    }
  }

  void testBucket() async {
    var url = Uri.https('upload.wikimedia.org',
        'wikipedia/commons/thumb/4/41/Sunflower_from_Silesia2.jpg/1200px-Sunflower_from_Silesia2.jpg');

    // Await the http get response, then decode the json-formatted response.
    var response = await http.get(url);
    if (response.statusCode == 200) {
      print('response.bodyBytes ${response.bodyBytes.length}');
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }

    // var listBuck = await client['main']!.storage.listBuckets();
    // if (listBuck.isEmpty) {
    //   await client['main']!.storage.createBucket(
    //       'avatars', const BucketOptions(public: false, fileSizeLimit: '2MB'));
    //   await client['main']!.storage.from('avatars').uploadBinary('path', data)
    // }

    //   public: false,
    //   allowedMimeTypes: ['image/png'],
    //   fileSizeLimit: 1024
    // })
  }
}
