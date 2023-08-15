import 'package:flutter/foundation.dart';

import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';

import '../store/driver.dart';
import 'core_provider.dart';

abstract class CoreDataLoader {
  addData(CoreDataEntity data);
  Future<List<CoreDataEntity>> getDataAsync();
  List<CoreDataEntity> getDataSync();
  bool isSync();
  saveData(dynamic content);
  deleteData(dynamic content);
  deleteAll();
  changed(CWProvider provider, CoreDataEntity entity);
  reorder(int oldIndex, int newIndex);
  reload();
  setFilter(CoreDataEntity? aFilter);
  CoreDataEntity? getFilter();
}

class CoreDataLoaderMap extends CoreDataLoader {
  final CWWidgetLoaderCtx _loader;

  String? _mapQueryId;
  final Map<String, CoreDataEntity> _dicoDataContainerEntity;
  final String _dataContainerAttribut;
  final Map<String, CoreDataEntity> _dicoFilter = {};

  final Map<String, Future<List<CoreDataEntity>>> _currentLoading = {};

  CoreDataLoaderMap(
      this._loader, this._dicoDataContainerEntity, this._dataContainerAttribut);

  @override
  addData(CoreDataEntity data) {
    CoreDataEntity resultQuery = _dicoDataContainerEntity[_mapQueryId]!;
    List<dynamic>? result = resultQuery.value[_dataContainerAttribut];
    result?.add(data.value);
  }

  @override
  Future<List<CoreDataEntity>> getDataAsync() async {
    _currentLoading[_mapQueryId!] =
        _currentLoading[_mapQueryId] ?? _getFuturData(_dicoFilter[_mapQueryId]);
    return _currentLoading[_mapQueryId]!;
  }

  @override
  reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    CoreDataEntity? selected = _dicoDataContainerEntity[_mapQueryId];
    List<dynamic> result = selected!.value[_dataContainerAttribut];
    final item = result.removeAt(oldIndex);
    result.insert(newIndex, item);
  }

  Future<List<CoreDataEntity>> _getFuturData(CoreDataEntity? filters) async {
    await _getDataContainerFromStore(_mapQueryId!, filters);

    List<CoreDataEntity> ret = [];
    CoreDataEntity? selected = _dicoDataContainerEntity[_mapQueryId];
    if (selected != null) {
      List<dynamic>? result = selected.value[_dataContainerAttribut];
      if (result != null) {
        for (Map<String, dynamic> element in result) {
          var ent = _loader.collectionDataModel.createEntity(element[r'$type']);
          ent.value = element;
          ret.add(ent);
        }
      }
    }
    return ret;
  }

  Future<CoreDataEntity> _getDataContainerFromStore(
      String idDataInMap, CoreDataEntity? filters) async {
    if (_dicoDataContainerEntity[idDataInMap] == null) {
      dynamic items;
      StoreDriver? storage = await StoreDriver.getDefautDriver("main");

      if (storage != null) {
        items = await storage.getJsonData(idDataInMap, filters);
      }
      if (items == null) {
        _dicoDataContainerEntity[idDataInMap] = _loader.collectionDataModel
            .createEntityByJson(
                "DataContainer", {"idData": idDataInMap, "listData": []});
        if (storage != null) {
          await storage.setData(
              'data', _dicoDataContainerEntity[idDataInMap]!.value);
        }
      } else {
        _dicoDataContainerEntity[idDataInMap] = _loader.collectionDataModel
            .createEntityByJson("DataContainer", items);
      }
    }
    debugPrint(
        "getDataFromQuery $idDataInMap = ${_dicoDataContainerEntity[idDataInMap]!}");
    var ret = _dicoDataContainerEntity[idDataInMap]!;
    return ret;
  }

  @override
  List<CoreDataEntity> getDataSync() {
    throw UnimplementedError();
  }

  @override
  bool isSync() {
    return false;
  }

  @override
  saveData(dynamic content) async {
    StoreDriver? storage = await StoreDriver.getDefautDriver("main");
    if (_dicoDataContainerEntity[_mapQueryId] != null && storage != null) {
      _dicoDataContainerEntity[_mapQueryId]!.value["listData"] = content;
      storage.setData(
          _mapQueryId!, _dicoDataContainerEntity[_mapQueryId]!.value);
    }
  }

  setMapID(String name) {
    _mapQueryId = name;
  }

  @override
  deleteAll() async {
    StoreDriver? storage = await StoreDriver.getDefautDriver("main");
    storage!.deleteTable(_mapQueryId!);
  }

  @override
  deleteData(content) async {
    StoreDriver? storage = await StoreDriver.getDefautDriver("main");
    if (_dicoDataContainerEntity[_mapQueryId] != null && storage != null) {
      await storage.deleteData(_mapQueryId!, content);
    }
  }

  @override
  changed(CWProvider provider, CoreDataEntity entity) {
    //entity.prepareChange(loader.collectionDataModel);
    entity.doChanged();
  }

  @override
  reload() {
    _dicoDataContainerEntity.remove(_mapQueryId);
    _currentLoading.remove(_mapQueryId);
  }

  @override
  setFilter(CoreDataEntity? aFilter) {
    if (aFilter == null) {
      _dicoFilter.remove(_mapQueryId);
    } else if (_mapQueryId != null) {
      _dicoFilter[_mapQueryId!] = aFilter;
    }
  }

  @override
  CoreDataEntity? getFilter() {
    if (_mapQueryId == null) return null;

    return _dicoFilter[_mapQueryId!];
  }
}

///////////////////////////////////////////////////////////////////////////////

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
  Future<List<CoreDataEntity>> getDataAsync() async {
    throw UnimplementedError();
  }

  @override
  List<CoreDataEntity> getDataSync() {
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
  saveData(dynamic content) {
    providerParent.getSelectedEntity()!.doChanged();
  }

  @override
  deleteAll() {}

  @override
  deleteData(content) {
    CoreDataEntity selected =
        providerParent.content[providerParent.idxSelected];
    List<dynamic> result = selected.value[attribut];
    for (var element in content as List) {
      result.remove(element);
    }
  }

  @override
  changed(CWProvider provider, CoreDataEntity entity) {
    //entity.prepareChange(loader.collectionDataModel);
    entity.doChanged();

    providerParent.getSelectedEntity()!.doChanged();
  }

  @override
  reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    CoreDataEntity selected =
        providerParent.content[providerParent.idxSelected];
    List<dynamic> result = selected.value[attribut];
    final item = result.removeAt(oldIndex);
    result.insert(newIndex, item);
    providerParent.getSelectedEntity()!.doChanged();
  }

  @override
  reload() {}

  @override
  setFilter(CoreDataEntity? aFilter) {}

  @override
  CoreDataEntity? getFilter() {
    return null;
  }
}
