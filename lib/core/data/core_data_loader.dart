import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';

import 'core_provider.dart';

abstract class CoreDataLoader {
  addData(CoreDataEntity data);
  List<CoreDataEntity> getData(CoreDataEntity? filters);
  saveDate();
}

class CoreDataLoaderMap extends CoreDataLoader {
  CWWidgetLoaderCtx loader;
  Map<String, CoreDataEntity> dicoData;
  String attribut;
  CoreDataLoaderMap(this.loader, this.dicoData, this.attribut);
  String? namedata;

  setName(String name) {
    namedata = name;
  }

  CoreDataEntity getDataFromQuery(String idData) {
    if (dicoData[idData] == null) {
      dicoData[idData] = loader.collectionDataModel.createEntityByJson(
          "DataContainer", {"idData": idData, "listData": []});
    }
    return dicoData[idData]!;
  }

  @override
  addData(CoreDataEntity data) {
    CoreDataEntity selected = dicoData[namedata]!;
    List<dynamic>? result = selected.value[attribut];
    result?.add(data.value);
  }

  @override
  List<CoreDataEntity> getData(CoreDataEntity? filters) {
    getDataFromQuery(namedata!);
    List<CoreDataEntity> ret = [];
    CoreDataEntity selected = dicoData[namedata]!;
    List<dynamic>? result = selected.value[attribut];
    if (result != null) {
      for (Map<String, dynamic> element in result) {
        var ent = loader.collectionDataModel.createEntity(element[r'$type']);
        ent.value = element;
        ret.add(ent);
      }
    }
    return ret;
  }

  @override
  saveDate() {}
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
  List<CoreDataEntity> getData(CoreDataEntity? filters) {
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
  saveDate() {}
}
