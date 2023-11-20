import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
// import 'package:flutter/services.dart';
// import 'package:rich_clipboard/rich_clipboard.dart';

import '../core/widget/cw_core_selector_overlay_action.dart';
import '../core/widget/cw_core_widget.dart';
import 'designer.dart';
import 'builder/prop_builder.dart';

final log = Logger('CoreDesignerSelector');

class CoreDesignerSelector {
  PropBuilder propBuilder = PropBuilder();
  String _lastSelectedPath = '';

  static final CoreDesignerSelector _current = CoreDesignerSelector();
  static CoreDesignerSelector of() {
    return _current;
  }

  CoreDesignerSelector() {
    log.fine('init event listener');

    CoreDesigner.on(CDDesignEvent.select, (arg) {
      CWWidgetCtx ctx = arg as CWWidgetCtx;
      ctx.refreshContext();
      log.finest('selection <${ctx.xid}> path=${ctx.pathWidget}');
      SelectorActionWidget.showActionWidget(ctx.inSlot!.key as GlobalKey);
    });

    CoreDesigner.on(CDDesignEvent.reselect, (arg) {
      if (arg is GlobalKey) {
        SelectorActionWidget.showActionWidget(arg);
      }
    });

    CoreDesigner.on(CDDesignEvent.select, (arg) {
      CWWidgetCtx ctx = arg as CWWidgetCtx;
      propBuilder.buildWidgetProperties(ctx, 1);
      unselect();
      _lastSelectedPath = ctx.pathWidget;
      CoreDesigner.of().editor.controllerTabRight.index = 0;

      // Future<RichClipboardData?> data = RichClipboard.getData();
      // data.then((clipboardData) {
      //   if (clipboardData?.html != null) {
      //     print("RichClipboardData html ${clipboardData?.html}");
      //   }
      //   if (clipboardData?.text != null) {
      //     print("RichClipboardData text ${clipboardData?.text}");
      //   }
      // });
    });

    CoreDesigner.on(CDDesignEvent.reselect, (arg) {
      if (arg == null) {
        SlotConfig? config =
            CoreDesigner.ofFactory().mapSlotConstraintByPath[_lastSelectedPath];

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

  CWWidgetCtx? getSelectedWidgetContext() {
    return CoreDesigner.ofView().getWidgetByPath(_lastSelectedPath)?.ctx;
  }

  CWWidgetCtx? getSelectedSlotContext() {
    return CoreDesigner.ofFactory()
        .mapSlotConstraintByPath[_lastSelectedPath]
        ?.slot
        ?.ctx;
  }

  void unselect() {
    String old = _lastSelectedPath;
    _lastSelectedPath = '';

    SlotConfig? config = CoreDesigner.ofFactory().mapSlotConstraintByPath[old];
    if (config != null) {
      log.finest('deselection <${config.xid}> path=${config.slot?.ctx.pathWidget}');
      // Future.delayed(const Duration(milliseconds: 1000), () {
      config.slot?.repaint();
      // });
    }
  }
}
