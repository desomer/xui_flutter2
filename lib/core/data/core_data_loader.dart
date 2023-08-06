import 'package:flutter/foundation.dart';

import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';

import '../store/driver.dart';
import 'core_provider.dart';

abstract class CoreDataLoader {
  addData(CoreDataEntity data);
  Future<List<CoreDataEntity>> getData(CoreDataEntity? filters);
  List<CoreDataEntity> getDataSync(CoreDataEntity? filters);
  bool isSync();
  saveData(dynamic content);
  deleteData(dynamic content);
  deleteAll(String idTable);
  changed(CWProvider provider, CoreDataEntity entity);
}

class CoreDataLoaderMap extends CoreDataLoader {
  CWWidgetLoaderCtx loader;
  Map<String, CoreDataEntity> dicoResultQuery;
  final Map<String, Future<List<CoreDataEntity>>> _currentLoading = {};
  String attribut;
  String? idQuery;
  CoreDataLoaderMap(this.loader, this.dicoResultQuery, this.attribut);

  @override
  addData(CoreDataEntity data) {
    CoreDataEntity resultQuery = dicoResultQuery[idQuery]!;
    List<dynamic>? result = resultQuery.value[attribut];
    result?.add(data.value);
  }

  @override
  Future<List<CoreDataEntity>> getData(CoreDataEntity? filters) async {
    _currentLoading[idQuery!] =
        _currentLoading[idQuery] ?? getDataCached(filters);
    return _currentLoading[idQuery]!;
  }

  Future<List<CoreDataEntity>> getDataCached(CoreDataEntity? filters) async {
    await getDataFromQuery(idQuery!);
    List<CoreDataEntity> ret = [];
    CoreDataEntity? selected = dicoResultQuery[idQuery];
    if (selected != null) {
      List<dynamic>? result = selected.value[attribut];
      if (result != null) {
        for (Map<String, dynamic> element in result) {
          var ent = loader.collectionDataModel.createEntity(element[r'$type']);
          ent.value = element;
          ret.add(ent);
        }
      }
    }
    return ret;
  }

  Future<CoreDataEntity> getDataFromQuery(String idDataInMap) async {
    if (dicoResultQuery[idDataInMap] == null) {
      dynamic items;
      StoreDriver? storage = await StoreDriver.getDefautDriver("main");

      if (storage != null) {
        items = await storage.getAllData(idDataInMap);
      }
      if (items == null) {
        dicoResultQuery[idDataInMap] = loader.collectionDataModel
            .createEntityByJson(
                "DataContainer", {"idData": idDataInMap, "listData": []});
        if (storage != null) {
          await storage.setData('data', dicoResultQuery[idDataInMap]!.value);
        }
      } else {
        dicoResultQuery[idDataInMap] = loader.collectionDataModel
            .createEntityByJson("DataContainer", items);
      }
    }
    debugPrint(
        "getDataFromQuery $idDataInMap = ${dicoResultQuery[idDataInMap]!}");
    return dicoResultQuery[idDataInMap]!;
  }

  @override
  List<CoreDataEntity> getDataSync(CoreDataEntity? filters) {
    throw UnimplementedError();
  }

  @override
  bool isSync() {
    return false;
  }

  @override
  saveData(dynamic content) async {
    StoreDriver? storage = await StoreDriver.getDefautDriver("main");
    if (dicoResultQuery[idQuery] != null && storage != null) {
      dicoResultQuery[idQuery]!.value["listData"] = content;
      storage.setData(idQuery!, dicoResultQuery[idQuery]!.value);
    }
  }

  setMapID(String name) {
    idQuery = name;
  }

  @override
  deleteAll(String idTable) async {
    StoreDriver? storage = await StoreDriver.getDefautDriver("main");
    storage!.deleteTable(idTable);
  }

  @override
  deleteData(content) async {
    StoreDriver? storage = await StoreDriver.getDefautDriver("main");
    if (dicoResultQuery[idQuery] != null && storage != null) {
      await storage.deleteData(idQuery!, content);
    }
  }

  @override
  changed(CWProvider provider, CoreDataEntity entity) {
    //entity.prepareChange(loader.collectionDataModel);
    entity.doChanged();
  }
}

class CoreDataLoaderNested extends CoreDataLoader {
  CWWidgetLoaderCtx loader;
  CWProvider providerParent;
  String attribut;
  CoreDataLoaderNested(this.loader, this.providerParent, this.attribut);

  @override
  addData(CoreDataEntity data) {
    if (providerParent.idxSelected >= 0 &&
        providerParent.idxSelected < providerParent.content.length) {
      CoreDataEntity selected =
          providerParent.content[providerParent.idxSelected];
      List<dynamic>? result = selected.value[attribut];
      result?.add(data.value);
    }
  }

  @override
  Future<List<CoreDataEntity>> getData(CoreDataEntity? filters) async {
    throw UnimplementedError();
  }

  @override
  List<CoreDataEntity> getDataSync(CoreDataEntity? filters) {
    List<CoreDataEntity> ret = [];
    if (providerParent.idxSelected >= 0 &&
        providerParent.idxSelected < providerParent.content.length) {
      CoreDataEntity selected =
          providerParent.content[providerParent.idxSelected];
      List<dynamic>? result = selected.value[attribut];
      if (result != null) {
        for (Map<String, dynamic> element in result) {
          var ent = loader.collectionDataModel.createEntity(element[r'$type']);
          ent.value = element;
          ret.add(ent);
        }
      }
    }
    return ret;
  }

  @override
  bool isSync() {
    return true;
  }

  @override
  saveData(dynamic content) {}

  @override
  deleteAll(String idTable) {}

  @override
  deleteData(content) {}

  @override
  changed(CWProvider provider, CoreDataEntity entity) {
    //entity.prepareChange(loader.collectionDataModel);
    entity.doChanged();

    providerParent.getSelectedEntity()!.doChanged();
  }
}
