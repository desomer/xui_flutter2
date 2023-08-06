import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xui_flutter/core/data/core_data.dart';

import '../driver.dart';

// postgre _r$y-74WSMFKk8

class SupabaseDriver extends StoreDriver {
  Map<String, SupabaseClient> client = {};
  String idCustomer = "demo";
  String idNamespace = "demo";

  Future<void> init() async {
    await Supabase.initialize(
      url: "https://pkrutsmghgjxapkozcyn.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBrcnV0c21naGdqeGFwa296Y3luIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTEyNzI4MjgsImV4cCI6MjAwNjg0ODgyOH0.nlADIUSTgwWCZ9Q2vUgr6iwPHBZwxSjLlQKCV_zdt8I",
    );

    // It's handy to then extract the Supabase client in a variable for later uses
    client['main'] = Supabase.instance.client;

    AuthResponse res = await client['main']!.auth.signInWithPassword(
          email: "gauthier.desomer@gmail.com",
          password: "Charley.30",
        );

    // ignore: unused_local_variable
    final Session? session = res.session;
    // ignore: unused_local_variable
    final User? user = res.user;

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
  }

  @override
  dynamic getAllData(String idTable) async {
    var ret = await client['main']!
        .from('ListModel')
        .select('json')
        .eq("idTable", idTable)
        .eq("idCustomer", idCustomer)
        .eq("idNamespace", idNamespace);
    if (ret is List) {
      if (ret.isNotEmpty) {
        var result = [];
        for (var r in ret) {
          result.add(json.decode(r["json"]));
        }
        return {
          r"$type": 'DataContainer',
          "idData": idTable,
          "listData": result
        };
      }
    }
    return null;
  }

  @override
  setData(String idTable, Map<String, dynamic> data) async {
    for (var element in data["listData"]) {
      if (element["_operation_"] == CDAction.create.index ||
          element["_operation_"] == CDAction.update.index) {
        element["_operation_"] = CDAction.read.index;
        await client['main']!.from('ListModel').upsert([
          {
            "idTable": idTable,
            "idCustomer": idCustomer,
            "idNamespace": idNamespace,
            "idData": element["_id_"],
            "json": json.encode(element)
          }
        ]); //.select('json').eq("idTable", idTable);
      }
    }
  }

  @override
  deleteTable(String idTable) async {
    await client['main']!
        .from('ListModel')
        .delete()
        .eq("idTable", idTable)
        .eq("idCustomer", idCustomer)
        .eq("idNamespace", idNamespace);

    print("delete table $idTable");
  }

  @override
  deleteData(String idTable, List data) async {
    for (var element in data) {
      await client['main']!
          .from('ListModel')
          .delete()
          .eq("idTable", idTable)
          .eq("idCustomer", idCustomer)
          .eq("idNamespace", idNamespace)
          .eq("idData", element["_id_"]);
      print("delete $idTable $element");
    }
  }
}