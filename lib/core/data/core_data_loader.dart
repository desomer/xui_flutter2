import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';

import 'core_provider.dart';

abstract class CoreDataLoader {
  List<CoreDataEntity> getData(CoreDataEntity? filters);
}

class CoreDataLoaderProvider extends CoreDataLoader {
  CoreDataLoaderProvider(this.loader, this.provider, this.attribut);
  CWWidgetLoaderCtx loader;
  CWProvider provider;
  String attribut;

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
}
