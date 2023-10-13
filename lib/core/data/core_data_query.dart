import 'package:flutter/material.dart';

import 'core_data.dart';
import 'core_provider.dart';

class CoreGlobalCacheResultQuery {
  static final Map<String, int> cacheNbData = {};
  static final Map<String, List<CoreDataEntity>> cacheDataValue = {};

  static void setCache(CWProvider provider, int nbrow) {
    String idCache = provider.name + provider.type;
    cacheNbData[idCache] = nbrow;
    debugPrint('set cache $idCache as $nbrow');
    if (nbrow == -1) {
      saveCache(provider);
    }
  }

  static void saveCache(CWProvider provider) {
    String idCache = provider.name + provider.type;
    List<CoreDataEntity> contentDeleted = [];
    List<dynamic> contentToSave = [];
    List<dynamic> contentToDelete = [];

    for (CoreDataEntity row in provider.content) {
      if (row.operation == CDAction.delete) {
        contentDeleted.add(row);
      } else {
        contentToSave.add(row.value);
      }
    }

    for (CoreDataEntity rowDeleted in contentDeleted) {
      provider.content.remove(rowDeleted);
      if (cacheNbData[idCache] != null) {
        cacheNbData[idCache] = cacheNbData[idCache]! - 1;
      }
      contentToDelete.add(rowDeleted.value);
    }

    debugPrint('save cache $idCache');
    if (contentToDelete.isNotEmpty) {
      provider.loader?.deleteData(contentToDelete);
    }
    if (contentToSave.isNotEmpty) {
      provider.loader?.saveData(contentToSave);
    }
  }

  static void setCacheValue(CWProvider provider, List<CoreDataEntity> rows) {
    String idCache = provider.name + provider.type;
    cacheDataValue[idCache] = rows;
    debugPrint('set cache value $idCache as ${rows.length}');
  }

  static void notifNewRow(CWProvider provider) {
    String idCache = provider.name + provider.type;
    int v = cacheNbData[idCache]!;
    cacheNbData[idCache] = v + 1;
  }
}

// class ResultQuery {
//   Future<int> nb;
//   Content
  
// }
