import 'package:logging/logging.dart';

import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';

import '../store/driver.dart';
import '../widget/cw_core_widget.dart';
import 'core_data_filter.dart';
import 'core_provider.dart';

abstract class CoreDataLoader {
  void addData(CoreDataEntity data);
  Future<List<CoreDataEntity>> getDataAsync(CWWidgetCtx ctx);
  List<CoreDataEntity> getDataSync();
  bool isSync();
  Future<void> saveData(dynamic content);
  Future<void> deleteData(dynamic content);
  void deleteAll();
  void changed(CWProvider provider, CoreDataEntity entity);
  void reorder(int oldIndex, int newIndex);
  void reload();
  void setFilter(CWProvider provider, CoreDataFilter? aFilter);
  CoreDataFilter? getFilter();
  void setCacheViewID(String cacheID, {required String onTable});
}

final log = Logger('CoreDataLoaderMap');

class CoreDataLoaderMap extends CoreDataLoader {
  final CWAppLoaderCtx _loader;

  String? _cacheViewId;
  String? _table;
  final String _dataContainerAttribut;

  final Map<String, CoreDataFilter> _dicoFilter = {};
  final Map<String, Future<List<CoreDataEntity>>> _currentLoading = {};
  final Map<String, CoreDataEntity> _dicoDataContainerEntity;

  CoreDataLoaderMap(
      this._loader, this._dicoDataContainerEntity, this._dataContainerAttribut);

  @override
  void addData(CoreDataEntity data) {
    CoreDataEntity resultQuery = _dicoDataContainerEntity[_cacheViewId]!;
    List<dynamic>? result = resultQuery.value[_dataContainerAttribut];
    result?.add(data.value);
  }

  @override
  Future<List<CoreDataEntity>> getDataAsync(CWWidgetCtx ctx) async {
    log.fine(
        'get async data table <$_table> idView=$_cacheViewId by ${ctx.pathWidget}');
    _currentLoading[_cacheViewId!] = _currentLoading[_cacheViewId] ??
        _getFuturData(_dicoFilter[_cacheViewId]?.dataFilter);
    return _currentLoading[_cacheViewId]!;
  }

  @override
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    CoreDataEntity? selected = _dicoDataContainerEntity[_cacheViewId];
    List<dynamic> result = selected!.value[_dataContainerAttribut];
    final item = result.removeAt(oldIndex);
    result.insert(newIndex, item);
  }

  Future<List<CoreDataEntity>> _getFuturData(CoreDataEntity? filters) async {
    await _getDataContainerFromStore(filters);

    List<CoreDataEntity> ret = [];
    CoreDataEntity? selected = _dicoDataContainerEntity[_cacheViewId];
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
      CoreDataEntity? filters) async {
    if (_dicoDataContainerEntity[_cacheViewId] == null) {
      dynamic items;
      StoreDriver? storage = await StoreDriver.getDefautDriver('main');

      if (storage != null) {
        items = await storage.getJsonData(_table!, filters);
      }
      if (items == null) {
        _dicoDataContainerEntity[_cacheViewId!] = _loader.collectionDataModel
            .createEntityByJson(
                'DataContainer', {'idData': _cacheViewId, 'listData': []});
        if (storage != null) {
          await storage.setData(
              'data', _dicoDataContainerEntity[_cacheViewId]!.value);
        }
      } else {
        _dicoDataContainerEntity[_cacheViewId!] = _loader.collectionDataModel
            .createEntityByJson('DataContainer', items);
      }
      log.finest(
          'getDataFromQuery viewId=<$_cacheViewId> = ${_dicoDataContainerEntity[_cacheViewId]!}');
    } else {
      log.finest('getDataFromCache viewId=<$_cacheViewId>');
    }
    var ret = _dicoDataContainerEntity[_cacheViewId]!;
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
  Future<void> saveData(dynamic content) async {
    StoreDriver? storage = await StoreDriver.getDefautDriver('main');
    if (_dicoDataContainerEntity[_cacheViewId] != null && storage != null) {
      _dicoDataContainerEntity[_cacheViewId]!.value['listData'] = content;
      storage.setData(_table!, _dicoDataContainerEntity[_cacheViewId]!.value);
    }
  }

  @override
  void setCacheViewID(String cacheID, {required String onTable}) {
    _cacheViewId = cacheID;
    _table = onTable;
  }

  @override
  void deleteAll() async {
    StoreDriver? storage = await StoreDriver.getDefautDriver('main');
    storage!.deleteTable(_table!);
  }

  @override
  Future<void> deleteData(content) async {
    StoreDriver? storage = await StoreDriver.getDefautDriver('main');
    if (_dicoDataContainerEntity[_cacheViewId] != null && storage != null) {
      await storage.deleteData(_table!, content);
    }
  }

  @override
  void changed(CWProvider provider, CoreDataEntity entity) {
    //entity.prepareChange(loader.collectionDataModel);
    entity.doChanged();
  }

  @override
  void reload() {
    _dicoDataContainerEntity.remove(_cacheViewId);
    _currentLoading.remove(_cacheViewId);
  }

  @override
  void setFilter(CWProvider provider, CoreDataFilter? aFilter) {
    if (aFilter == null) {
      _dicoFilter.remove(_cacheViewId);
    } else if (_cacheViewId != null) {
      var providerCacheID = provider.getProviderCacheID(aFilter: aFilter);
      _dicoFilter[providerCacheID] = aFilter;
      log.fine('set filter on $providerCacheID');
    }
  }

  @override
  CoreDataFilter? getFilter() {
    if (_cacheViewId == null) return null;
    return _dicoFilter[_cacheViewId!];
  }
}

///////////////////////////////////////////////////////////////////////////////

class CoreDataLoaderNested extends CoreDataLoader {
  CWAppLoaderCtx loader;
  CWProvider providerParent;
  String attribut;
  CoreDataLoaderNested(this.loader, this.providerParent, this.attribut);

  @override
  void addData(CoreDataEntity data) {
    CoreDataEntity? selected = providerParent.getSelectedEntity();
    if (selected != null) {
      List<dynamic>? result = selected.value[attribut];
      result?.add(data.value);
    }
  }

  @override
  Future<List<CoreDataEntity>> getDataAsync(CWWidgetCtx ctx) async {
    throw UnimplementedError();
  }

  @override
  List<CoreDataEntity> getDataSync() {
    List<CoreDataEntity> ret = [];
    CoreDataEntity? selected = providerParent.getSelectedEntity();
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
  bool isSync() {
    return true;
  }

  @override
  Future<void> saveData(dynamic content) async {
    providerParent.getSelectedEntity()!.doChanged();
  }

  @override
  void deleteAll() {}

  @override
  Future<void> deleteData(content) async {
    CoreDataEntity selected = providerParent.getSelectedEntity()!;
    List<dynamic> result = selected.value[attribut];
    for (var element in content as List) {
      result.remove(element);
    }
  }

  @override
  void changed(CWProvider provider, CoreDataEntity entity) {
    //entity.prepareChange(loader.collectionDataModel);
    entity.doChanged();

    providerParent.getSelectedEntity()!.doChanged();
  }

  @override
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    CoreDataEntity selected = providerParent.getSelectedEntity()!;
    List<dynamic> result = selected.value[attribut];
    final item = result.removeAt(oldIndex);
    result.insert(newIndex, item);
    providerParent.getSelectedEntity()!.doChanged();
  }

  @override
  void reload() {}

  @override
  void setFilter(CWProvider provider, CoreDataFilter? aFilter) {}

  @override
  CoreDataFilter? getFilter() {
    return null;
  }
  
  @override
  void setCacheViewID(String cacheID, {required String onTable}) {
  }
}
