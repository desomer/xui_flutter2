import 'package:xui_flutter/core/data/core_repository.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/widget/cw_array.dart';
import 'package:xui_flutter/widget/cw_list.dart';

class CWSynchonizedManager {
  bool initSyncho = false;
  CoreDataAction? onRowSelected;
  CoreDataAction? onRefreshEntities;
  CoreDataAction? onValidateEntity;
  CWRepository? repository;

  void initAction(CWWidget widget, CWRepository? repository) {
    if (!initSyncho) {
      // redesine à l'action de selection
      onRowSelected = repository?.addAction(
          CWRepositoryAction.onRowSelected, ActionRepaintRow(widget.ctx));
      onValidateEntity = repository?.addAction(
          CWRepositoryAction.onValidateEntity, ActionRepaintRow(widget.ctx));
      onRefreshEntities = repository?.addAction(
          CWRepositoryAction.onRefreshEntities,
          ActionRepaint(widget.ctx, onFirst: true));
      initSyncho = true;
    }
  }

  void dispose() {
    repository?.removeAction(CWRepositoryAction.onRowSelected, onRowSelected);
    repository?.removeAction(
        CWRepositoryAction.onRefreshEntities, onRefreshEntities);
    repository?.removeAction(
        CWRepositoryAction.onValidateEntity, onValidateEntity);
    onRowSelected = null;
    onRefreshEntities = null;
    onValidateEntity = null;
    initSyncho = false;
  }
}

//////////////////////////////////////////////////////////////////////////////
class LinkInfo {
  final Map<String, LinkAttrInfo> reposXattr = {};
  final listUseXid = <String, int>{};

  void dispose() {
    listUseXid.clear();
    reposXattr.clear();
  }

  void add(CWWidget widget, String providerID, String attr) {
    LinkAttrInfo? info = reposXattr[providerID];
    if (info == null) {
      info = LinkAttrInfo();
      reposXattr[providerID] = info;
    }
    var attrInfo = info.attrXxid[attr];
    if (attrInfo == null) {
      attrInfo = [];
      info.attrXxid[attr] = attrInfo;
    }
    attrInfo.add(widget.ctx.xid);
  }
}

class LinkAttrInfo {
  final Map<String, List<String>> attrXxid = {};
}

//////////////////////////////////////////////////////////////////////////////

class ActionRepaint extends CoreDataAction {
  ActionRepaint(this.ctxRepaint, {this.onFirst});
  CWWidgetCtx ctxRepaint;
  bool? onFirst;

  @override
  void execute(CWWidgetCtx? ctx, CWWidgetEvent? event) {
    CWWidget w = ctxRepaint.getCWWidget()!;
    if (w is CWArray) {
      w.repaint();
    } else if (w is CWWidgetWithChild) {
      if (onFirst ?? false) {
        w.getRepository()?.displayRenderingMode = DisplayRenderingMode.selected;
        w.getRepository()?.getData().idxSelected = 0;
      }
      for (var we in w.getChildren()) {
        we.repaint();
      }
    }
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
      CWWidget w = ctxRepaint.getCWWidget()!;
      if (w is CWArray) {
        w.repaint();
      } else if (w is CWWidgetWithChild) {
        for (var we in w.getChildren()) {
          if (we is CWWidgetMapValue) {
            we.repaint();
          }
        }
      }
    }
  }
}
