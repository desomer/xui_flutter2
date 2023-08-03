import 'package:flutter/foundation.dart';
import 'package:localstorage/localstorage.dart';
import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';

import 'core_provider.dart';

abstract class CoreDataLoader {
  addData(CoreDataEntity data);
  Future<List<CoreDataEntity>> getData(CoreDataEntity? filters);
  List<CoreDataEntity> getDataSync(CoreDataEntity? filters);
  saveData();
  bool isSync();
}

class CoreDataLoaderMap extends CoreDataLoader {
  CWWidgetLoaderCtx loader;
  Map<String, CoreDataEntity> dicoResultQuery;
  String attribut;
  CoreDataLoaderMap(this.loader, this.dicoResultQuery, this.attribut);
  String? namedata;

  setMapName(String name) {
    namedata = name;
  }

  Future<CoreDataEntity> getDataFromQuery(String idData) async {
    if (dicoResultQuery[idData] == null) {
      final LocalStorage storage = LocalStorage('$idData.json');
      await storage.ready;
      await Future.delayed(const Duration(seconds: 2));
      var items = storage.getItem('data');
      if (items == null) {
        dicoResultQuery[idData] = loader.collectionDataModel.createEntityByJson(
            "DataContainer", {"idData": idData, "listData": []});
        storage.setItem('data', dicoResultQuery[idData]!.value);
      } else {
        dicoResultQuery[idData] = loader.collectionDataModel
            .createEntityByJson("DataContainer", items);
      }
    }
    debugPrint("getDataFromQuery $idData = ${dicoResultQuery[idData]!}");
    return dicoResultQuery[idData]!;
  }

  @override
  addData(CoreDataEntity data) {
    CoreDataEntity resultQuery = dicoResultQuery[namedata]!;
    List<dynamic>? result = resultQuery.value[attribut];
    result?.add(data.value);
  }

  @override
  Future<List<CoreDataEntity>> getData(CoreDataEntity? filters) async {
    await getDataFromQuery(namedata!);
    List<CoreDataEntity> ret = [];
    CoreDataEntity? selected = dicoResultQuery[namedata];
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

  @override
  saveData() async {
    if (dicoResultQuery[namedata] != null) {
      final LocalStorage storage = LocalStorage('$namedata.json');
      await storage.ready;
      storage.setItem('data', dicoResultQuery[namedata]!.value);
    }
  }

  @override
  List<CoreDataEntity> getDataSync(CoreDataEntity? filters) {
    throw UnimplementedError();
  }

  @override
  bool isSync() {
    return false;
  }
}

class CoreDataLoaderNested extends CoreDataLoader {
  CWWidgetLoaderCtx loader;
  CWProvider provider;
  String attribut;
  CoreDataLoaderNested(this.loader, this.provider, this.attribut);

  @override
  addData(CoreDataEntity data) {
    if (provider.idxSelected >= 0 &&
        provider.idxSelected < provider.content.length) {
      CoreDataEntity selected = provider.content[provider.idxSelected];
      List<dynamic>? result = selected.value[attribut];
      result?.add(data.value);
    }
  }

  @override
  Future<List<CoreDataEntity>> getData(CoreDataEntity? filters) async {
    throw UnimplementedError();
  }

  @override
  saveData() {}

  @override
  List<CoreDataEntity> getDataSync(CoreDataEntity? filters) {
    List<CoreDataEntity> ret = [];
    if (provider.idxSelected >= 0 &&
        provider.idxSelected < provider.content.length) {
      CoreDataEntity selected = provider.content[provider.idxSelected];
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
}
