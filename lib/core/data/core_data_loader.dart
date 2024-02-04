import 'package:logging/logging.dart';

import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';

import '../store/driver.dart';
import '../widget/cw_core_widget.dart';
import 'core_data_filter.dart';
import 'core_repository.dart';

abstract class CoreDataLoader {
  void addData(CoreDataEntity data);
  Future<List<CoreDataEntity>> getDataAsync(CWWidgetCtx ctx);
  List<CoreDataEntity> getDataSync();
  bool isSync();
  Future<void> saveData(dynamic content);
  Future<void> deleteData(dynamic content);
  void deleteAll();
  void changed(CWRepository provider, CoreDataEntity entity);
  void reorder(int oldIndex, int newIndex);
  void reload();
  void setFilter(CWRepository provider, CoreDataFilter? aFilter);
  CoreDataFilter? getFilter();
  void setCacheViewID(CWRepository provider);
  String? getCacheViewID();
}

final log = Logger('CoreDataLoaderMap');

class CoreDataLoaderMap extends CoreDataLoader {
  final CWAppLoaderCtx _loader;

  String? _filterID;
  String? _cacheViewId;
  String? _table;


  final Map<String, CoreDataFilter> _dicoFilter = {};
  final Map<String, Future<List<CoreDataEntity>>> _currentLoading = {};

  final Map<String, CoreDataEntity> _dicoDataContainerEntity;
  final String _dataContainerAttribut;

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
    var f = _dicoFilter[_filterID];
    log.fine(
        'loader get async table <$_table> idView=$_cacheViewId by ${ctx.pathWidget} with query h=${f.hashCode}');
    _currentLoading[_cacheViewId!] =
        _currentLoading[_cacheViewId] ?? _getFuturData(f?.dataFilter);
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

      log.finest('get query with filter h=${filters.hashCode}');

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
          'getData FromQuery viewId=<$_cacheViewId> = ${_dicoDataContainerEntity[_cacheViewId]!}');
    } else {
      log.finest('getData FromCache viewId=<$_cacheViewId>');
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
  void setCacheViewID(CWRepository provider) {
    _filterID = provider.type;
    var cacheID = provider.getRepositoryCacheID();
    _cacheViewId = cacheID;
    _table = provider.type;
    log.finest('set loader on loader <$_table> cacheID=$cacheID');
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
  void changed(CWRepository provider, CoreDataEntity entity) {
    //entity.prepareChange(loader.collectionDataModel);
    entity.doChanged();
  }

  @override
  void reload() {
    _dicoDataContainerEntity.remove(_cacheViewId);
    _currentLoading.remove(_cacheViewId);
  }

  @override
  void setFilter(CWRepository provider, CoreDataFilter? aFilter) {
    if (aFilter == null) {
      _dicoFilter.remove(_filterID);
    } else {
      // if (_cacheViewId != null)
      _filterID = provider.type;
      //provider.getRepositoryCacheID(aFilter: aFilter);
      _dicoFilter[_filterID!] = aFilter;
      log.fine(
          'set filter on $_filterID id=${provider.id} h=${aFilter.hashCode}');
    }
  }

  @override
  CoreDataFilter? getFilter() {
    if (_filterID == null) return null;
    return _dicoFilter[_filterID!];
  }

  @override
  String? getCacheViewID() {
    return _cacheViewId;
  }
}

///////////////////////////////////////////////////////////////////////////////

class CoreDataLoaderNested extends CoreDataLoader {
  CWAppLoaderCtx loader;
  CWRepository providerParent;
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
  void changed(CWRepository provider, CoreDataEntity entity) {
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
  void setFilter(CWRepository provider, CoreDataFilter? aFilter) {}

  @override
  CoreDataFilter? getFilter() {
    return null;
  }

  @override
  void setCacheViewID(CWRepository provider) {}

  @override
  String? getCacheViewID() {
    // TODO: implement getCacheViewID
    throw UnimplementedError();
  }
}
