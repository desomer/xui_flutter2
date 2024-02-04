import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
// import 'package:flutter/services.dart';
// import 'package:rich_clipboard/rich_clipboard.dart';

import '../core/widget/cw_core_selector_overlay_action.dart';
import '../core/widget/cw_core_widget.dart';
import 'builder/style_builder.dart';
import 'designer.dart';
import 'builder/prop_builder.dart';

final log = Logger('CoreDesignerSelector');

//const redisplayProp = 'redisplayProp';

class CoreDesignerSelector {
  PropBuilder propBuilder = PropBuilder();
  StyleBuilder styleBuilder = StyleBuilder();
  String _lastSelectedPath = '';
  int _lastTimeSelected = 0;

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
      SelectorActionWidget.showActionWidget(getInfoSelector(ctx));
      CoreDesigner.emit(CDDesignEvent.displayProp, ctx);
      unselect();
      _lastSelectedPath = ctx.pathWidget;
      _lastTimeSelected = DateTime.now().millisecondsSinceEpoch;
      //CoreDesigner.of().editor.controllerTabRight.index = 0;

      // ignore: invalid_use_of_protected_member
      CoreDesigner.of().navCmpKey.currentState?.setState(() {});
    });

    // CoreDesigner.on(CDDesignEvent.reselect, (arg) {

    // });

    // CoreDesigner.on(CDDesignEvent.select, (arg) {
    //  // CWWidgetCtx ctx = arg as CWWidgetCtx;

    //   // Future<RichClipboardData?> data = RichClipboard.getData();
    //   // data.then((clipboardData) {
    //   //   if (clipboardData?.html != null) {
    //   //     print("RichClipboardData html ${clipboardData?.html}");
    //   //   }
    //   //   if (clipboardData?.text != null) {
    //   //     print("RichClipboardData text ${clipboardData?.text}");
    //   //   }
    //   // });
    // });
    CoreDesigner.on(CDDesignEvent.displayProp, (arg) {
      if (arg == null) {
        SlotConfig? config =
            CoreDesigner.ofFactory().mapSlotConstraintByPath[_lastSelectedPath];
        arg = config!.slot!.ctx;
      }
      doWidgetProperties(arg as CWWidgetCtx);
    });

    CoreDesigner.on(CDDesignEvent.over, (arg) {
      CWWidgetCtx ctx = arg as CWWidgetCtx;
      ctx.refreshContext();
      log.finest('over <${ctx.xid}> path=${ctx.pathWidget}');
      SelectorActionWidget.showActionWidget(getInfoSelector(ctx));
    });

    CoreDesigner.on(CDDesignEvent.reselect, (arg) {
      if (arg is CWWidgetInfoSelector) {
        SelectorActionWidget.showActionWidget(arg);
      } else if (arg == null /*|| arg == redisplayProp*/) {
        SlotConfig? config =
            CoreDesigner.ofFactory().mapSlotConstraintByPath[_lastSelectedPath];

        if (config != null && config.slot != null) {
          // if (arg == redisplayProp) {
          //   doWidgetProperties(config.slot!.ctx);
          // }
          CoreDesigner.emit(
              CDDesignEvent.reselect, getInfoSelector(config.slot!.ctx));
        }
      }
    });
  }

  void doWidgetProperties(CWWidgetCtx ctx) {
    if (CoreDesigner.of().editor.controllerTabRight.index == 0) {
      propBuilder.buildWidgetProperties(ctx, 1);
    }
    if (CoreDesigner.of().editor.controllerTabRight.index == 1) {
      styleBuilder.buildWidgetProperties(ctx, 1);
    }
  }

  CWWidgetInfoSelector getInfoSelector(CWWidgetCtx ctx) {
    GlobalKey k = ctx.inSlot?.key as GlobalKey;
    CWWidgetInfoSelector? kc = ctx.getWidgetInSlot()?.ctx.infoSelector;
    if (kc != null) {
      kc.slotKey = k;
      return kc;
    }
    return ctx.infoSelector..slotKey = k;
  }

  bool isSelectedWidget(CWWidgetCtx ctx) {
    return _lastSelectedPath == ctx.pathWidget;
  }

  bool isSelectedWidgetSince(CWWidgetCtx ctx, int delay) {
    return _lastSelectedPath == ctx.pathWidget &&
        (DateTime.now().millisecondsSinceEpoch - _lastTimeSelected > delay);
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

  @Deprecated('plus utile')
  void unselect() {
    String old = _lastSelectedPath;
    _lastSelectedPath = '';

    SlotConfig? config = CoreDesigner.ofFactory().mapSlotConstraintByPath[old];
    if (config != null) {
      log.finest(
          'deselection <${config.xid}> path=${config.slot?.ctx.pathWidget}');
      // Future.delayed(const Duration(milliseconds: 1000), () {
      //config.slot?.repaint();
      // });
    }
  }
}
