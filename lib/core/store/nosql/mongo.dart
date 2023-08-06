import 'package:mongo_dart/mongo_dart.dart';

class StartMongo {
  void init() async {
    var db = await Db.create(
        "mongodb+srv://gauthierdesomer:ycf9fmkWQHqo7cGQ@elisview.otznoja.mongodb.net/toto?retryWrites=true&w=majority");
    await db.open();
    var n = await db.getCollectionNames();

    

    print("n= $n");

    var coll = db.collection('sample_airbnb.listingsAndReeeeeeeviews');
    var ret = await coll.find(where.limit(5)).toList();
    var a = db.collection('untest');
    await a.insertOne({"a": 12});

    print(ret);

    await db.close();
  }
}
