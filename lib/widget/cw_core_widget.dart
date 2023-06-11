import 'package:flutter/material.dart';

import '../core/core_data.dart';
import 'cw_builder.dart';

// ignore: must_be_immutable
abstract class CWWidget extends StatefulWidget {
  CWWidget({super.key, required this.ctx});
  CWWidgetCtx ctx;
  initSlot(String path);

  void addSlotPath(String pathWid, String xid) {
    final String childXid = ctx.factory.mapChildXidByXid[xid] ?? '';
    debugPrint('add slot >>>> $pathWid  $xid childXid=$childXid');
    Widget? w = ctx.factory.mapWidgetByXid[childXid];

    if (w is CWWidget) {
      ctx.factory.mapXidByPath[pathWid] = childXid;
      w.ctx.pathWidget = pathWid;
      w.initSlot(pathWid);
    }
  }

  CWWidgetCtx createChildCtx(String id, int? idx) {
    return CWWidgetCtx('${ctx.xid}$id$idx', ctx.factory,
        '${ctx.pathWidget}.$id${idx?.toString() ?? ''}');
  }
}

class CWWidgetCtx {
  CWWidgetCtx(this.xid, this.factory, this.pathWidget);
  String xid;
  String pathWidget;
  WidgetFactoryEventHandler factory;
  CoreDataEntity? entity;
  String? pathDataDesign;
  String? pathDataCreate;
}
