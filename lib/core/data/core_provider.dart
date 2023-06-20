import 'core_data.dart';

enum CWProviderAction { onStateInsert, onChange }

class CWProvider {
  CWProvider(this.current);
  CoreDataEntity current;
  Map<CWProviderAction, List<CoreDataAction>> actions = {};
}