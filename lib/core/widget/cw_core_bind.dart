import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_data.dart';

import '../data/core_provider.dart';

enum ModeBindWidget { selected }

class CWBindWidget {
  CWBindWidget(this.id, this.modeBindWidget);

  String id;
  State? nestedWidgetState;
  CWProvider? masterProvider;
  ModeBindWidget modeBindWidget;
  Function(CoreDataEntity)? fctBindNested;
  CoreDataEntity? currentEntity;

  void bindNested(CoreDataEntity item) {
    currentEntity = item;
    if (fctBindNested != null) {
      fctBindNested!(item);
    }
  }

  void onSelect(CoreDataEntity item) {
    if (modeBindWidget == ModeBindWidget.selected) {
      bindNested(item);
      if (nestedWidgetState?.mounted ?? false) {
        // ignore: invalid_use_of_protected_member
        nestedWidgetState?.setState(() {});
      }
    }
  }

  void repaint() {
    if (nestedWidgetState?.mounted ?? false) {
      // ignore: invalid_use_of_protected_member
      nestedWidgetState?.setState(() {});
    }
  }
}
