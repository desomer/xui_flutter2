import 'package:xui_flutter/core/data/core_repository.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/widget/cw_list.dart';

class CWSynchonizedManager {
  bool initSyncho = false;

  void initRepaintOnSelected(CWWidget widget, CWRepository? repository) {
    if (!initSyncho) {
      // redesine à l'action de selection
      repository?.addAction(
          CWRepositoryAction.onRowSelected, ActionRepaint(widget.ctx));
      initSyncho = true;
    }
  }
}

class ActionRepaint extends CoreDataAction {
  ActionRepaint(this.ctxRepaint);
  CWWidgetCtx ctxRepaint;

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    ctxRepaint.getCWWidget()?.repaint();
  }
}

class ActionRepaintRow extends CoreDataAction {
  ActionRepaintRow(this.ctxRepaint);
  CWWidgetCtx ctxRepaint;

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    if (event?.payload is InheritedRow) {
      var r = event?.payload as InheritedRow;
      r.repaintRow(ctxRepaint);
    } else {
      ctxRepaint.getCWWidget()?.repaint();
    }
  }
}
