import 'package:flutter/material.dart';

import 'core_data.dart';
import 'core_provider.dart';

class CacheResultQuery {
  static final Map<String, int> cacheNbData = {};
  static final Map<String, List<CoreDataEntity>> cacheDataValue = {};

  static setCache(CWProvider provider, int nbrow) {
    String idCache = provider.name + provider.type;
    cacheNbData[idCache] = nbrow;
    debugPrint("set cache $idCache as $nbrow");
    if (nbrow == -1) {
      provider.loader?.saveData();
    }
  }

  static saveCache(CWProvider provider) {
    String idCache = provider.name + provider.type;
    debugPrint("save cache $idCache");
    provider.loader?.saveData();
  }  

  static setCacheValue(CWProvider provider, List<CoreDataEntity> rows) {
    String idCache = provider.name + provider.type;
    cacheDataValue[idCache] = rows;
    debugPrint("set cache value $idCache as ${rows.length}");
  }

  static notifNewRow(CWProvider provider) {
    String idCache = provider.name + provider.type;
    int v = cacheNbData[idCache]!;
    cacheNbData[idCache] = v + 1;
  }
}

// class ResultQuery {
//   Future<int> nb;
//   Content
  
// }
