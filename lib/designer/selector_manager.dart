import 'package:flutter/material.dart';

import '../core/widget/cw_core_widget.dart';
import 'designer.dart';
import 'prop_builder.dart';

class CoreDesignerSelector {
  PropBuilder propBuilder = PropBuilder();
  String _lastSelectedPath = '';

  static final CoreDesignerSelector _current = CoreDesignerSelector();
  static CoreDesignerSelector of() {
    return _current;
  }

  CoreDesignerSelector() {
    CoreDesigner.on(CDDesignEvent.select, (arg) {
      CWWidgetCtx ctx = arg as CWWidgetCtx;
      propBuilder.buildWidgetProperties(ctx, 1);
      unselect();
      _lastSelectedPath = ctx.pathWidget;
    });

    CoreDesigner.on(CDDesignEvent.reselect, (arg) {
      if (arg == null) {
        SlotConfig? config = CoreDesigner.of()
            .factory
            .mapSlotConstraintByPath[_lastSelectedPath];

        if (config != null && config.slot != null) {
          CoreDesigner.emit(
              CDDesignEvent.reselect, config.slot!.key as GlobalKey);
        }
      }
    });
  }

  bool isSelectedWidget(CWWidgetCtx ctx) {
    return _lastSelectedPath == ctx.pathWidget;
  }

  void unselect() {
    String old = _lastSelectedPath;
    _lastSelectedPath = "";

    SlotConfig? config = CoreDesigner.of().factory.mapSlotConstraintByPath[old];
    if (config != null) {
      debugPrint("deselection ${config.xid}");
      // Future.delayed(const Duration(milliseconds: 1000), () {
      config.slot?.repaint();
      // });
    }
  }
}
