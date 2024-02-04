import 'package:logging/logging.dart';

import 'core_data.dart';
import 'core_repository.dart';

final log = Logger('CoreGlobalCache');

class CoreGlobalCache {
  static final Map<String, int> cacheNbData = {};
  static final Map<String, List<CoreDataEntity>> cacheDataValue = {};

  static void setCache(CWRepository provider, int nbrow) {
    String idCache = provider.getRepositoryCacheID();
    cacheNbData[idCache] = nbrow;
    if (nbrow == -1) {
      log.finer('save cache on bdd <$idCache> with $nbrow rows');
      saveCache(provider);
    } else {
      log.finer('set cache nbrow <$idCache> with $nbrow rows');
      provider.lockId = null;
    }
  }

  static int getCacheNbRow(CWRepository provider) {
    String idCache = provider.getRepositoryCacheID();
    var cacheNbRow = cacheNbData[idCache];
    if (cacheNbRow != null && cacheNbRow != -1) {
      var result = cacheDataValue[idCache];
      provider.content = result!;
      return cacheNbRow;
    }
    return -1;
  }

  static Future<void> saveCache(CWRepository provider) async {
    String idCache = provider.getRepositoryCacheID();
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

    if (contentToDelete.isNotEmpty) {
      await provider.loader?.deleteData(contentToDelete);
    }
    if (contentToSave.isNotEmpty) {
      await provider.loader?.saveData(contentToSave);
    }
  }

  static void setCacheValue(CWRepository provider, List<CoreDataEntity> rows) {
    String idCache = provider.getRepositoryCacheID();
    cacheDataValue[idCache] = rows;
    log.finer(
        'set cache value <$idCache> with ${rows.length} json; nb Cache = ${cacheDataValue.length}');
  }

  static void notifNewRow(CWRepository provider) {
    String idCache = provider.getRepositoryCacheID();
    int v = cacheNbData[idCache]!;
    cacheNbData[idCache] = v + 1;
  }
}

// class ResultQuery {
//   Future<int> nb;
//   Content
  
// }
