// ignore: depend_on_referenced_packages
import 'package:convert/convert.dart';
import 'package:flutter/widgets.dart';

import '../core/core_data.dart';
import '../core/core_event.dart';

///-------------------------------------------------------------------------
class WidgetColumn extends CoreWidgetFactory {
  @override
  void processWidget(CoreDataCtx ctx, CoreWidgetCtx ctxW) {
    final List<Widget> c = (ctxW.current!.param['children']) as List<Widget>;
    ctxW.current!.widgetValue = Column(children: c);
  }
}

///---------------------------------------------------------------------
///
class WidgetText extends CoreWidgetFactory {
  @override
  void processWidget(CoreDataCtx ctx, CoreWidgetCtx ctxW) {
    ctxW.current!.widgetValue = Text(getString('data', ctx.event!)!,
        style: getTextStyle('style', ctxW.current!));
  }
}

class WidgetTextStyle extends CoreWidgetFactory {
  @override
  void processWidget(CoreDataCtx ctx, CoreWidgetCtx ctxW) {
    ctxW.current!.widgetValue = TextStyle(
        color: getColor('color', ctx.event!),
        fontSize: getDouble('fontSize', ctx.event!));
  }
}

///---------------------------------------------------------------------

class CoreWidgetFactory {
  CoreWidget? processInitWidget(CoreDataCtx ctx, CoreWidgetCtx ctxW) {
    final CoreWidget ret = CoreWidget();
    ret.type = ctx.event!.builder.name;
    //print("object *************** ${ctx.event!.src}");
    return ret;
  }

  void processWidget(CoreDataCtx ctx, CoreWidgetCtx ctxW) {}

  void processProp(CoreDataCtx ctx, CoreWidgetCtx ctxW) {
    // init les one 2 one
    if (ctx.event!.attr.type == CDAttributType.CDone) {
      ctxW.current!.param[ctx.event!.attr.name] = ctxW.current!.widgetValue;
    }

    // init les one 2 many
    if (ctx.event!.attr.type == CDAttributType.CDmany) {
      if (ctx.event!.attr.typeName == 'Widget') {
        ctxW.current!.param[ctx.event!.attr.name] = <Widget>[];
      }
    }
  }

  TextStyle? getTextStyle(String key, CoreWidget current) {
    TextStyle? s;
    if (current.param['style'] != null) {
      s = current.param['style'] as TextStyle;
    }
    return s;
  }

  Color? getColor(String key, CoreDataEvent event) {
    //print("color ========= ${event.src[key]}");

    Color? c;
    if (event.src[key] != null) {
      final List<int> h = hex.decode(event.src[key].toString());
      c = Color.fromARGB(h[3], h[0], h[1], h[2]);
    }
    return c;
  }

  String? getString(String key, CoreDataEvent event) {
    return event.src[key] as String?;
  }

  double? getDouble(String key, CoreDataEvent event) {
    return event.src[key] as double?;
  }
}

////////////////////////////////////////////////////////////////
class CoreWidgetCtx {
  CoreWidgetCtx(this.current, this.parent);

  CoreWidget? current;
  CoreWidget? parent;
}

class CoreWidget {
  String? type;
  dynamic widgetValue;
  Map<String, dynamic> param = <String, dynamic>{};

  String getPString(String key) {
    return param[key] as String;
  }
}

class CoreWidgetFactoryEventHandler extends CoreEventHandler {
  CoreWidgetFactoryEventHandler() {
    dictionaryWidgets['Column'] = WidgetColumn();
    dictionaryWidgets['Text'] = WidgetText();
    dictionaryWidgets['TextStyle'] = WidgetTextStyle();
  }

  Widget? root;
  Map<String, CoreWidgetFactory> dictionaryWidgets =
      <String, CoreWidgetFactory>{};
  Map<String, CoreWidget> tree = <String, CoreWidget>{};

  void trace(String str) {
    //print(str);
  }

  @override
  void process(CoreDataCtx ctx) {
    super.process(ctx);

    final String id = ctx.getPathData();
    String idParent = '';
    if (id.isNotEmpty) {
      final int idx = id.lastIndexOf('.');
      if (idx > 0) {
        idParent = id.substring(0, idx);
      }
    }

    if (ctx.event!.action == 'browserObject') {
      trace('---> start object ${ctx.event!.builder.name} id=$id');

      final CoreWidget? widgetHandle =
          dictionaryWidgets[ctx.event!.builder.name]
              ?.processInitWidget(ctx, CoreWidgetCtx(null, tree[idParent]));

      if (widgetHandle != null) {
        tree[id] = widgetHandle;
      }
    }

    if (ctx.event!.action == 'browserObjectEnd') {
      trace('---> end object ${ctx.event!.builder.name} on $id pa=$idParent');
      final CoreWidget? widgetHandle = tree[id];
      if (widgetHandle != null) {
        dictionaryWidgets[ctx.event!.builder.name]
            ?.processWidget(ctx, CoreWidgetCtx(widgetHandle, tree[idParent]));
        if (ctx.pathData.isEmpty) {
          root = widgetHandle.widgetValue as Widget;
        } else {
          if (widgetHandle.widgetValue != null) {
            final CoreWidget parentHandle = tree[idParent]!;
            trace(
                'set object ${widgetHandle.widgetValue!} on type=${parentHandle.type!}');
            parentHandle.widgetValue = widgetHandle.widgetValue;
            final CoreWidget pHandle = CoreWidget();
            pHandle.widgetValue = widgetHandle.widgetValue;
            pHandle.param = parentHandle.param;

            dictionaryWidgets[parentHandle.type]
                ?.processProp(ctx, CoreWidgetCtx(pHandle, null));
          }
        }
      }
    }

    if (ctx.event!.action == 'browserObjectEndItem') {
      trace('---> end Item ${ctx.event!.builder.name} on $id pa=$idParent');
      final CoreWidget? widgetHandle = tree[id];
      if (widgetHandle != null) {
        dictionaryWidgets[ctx.event!.builder.name]
            ?.processWidget(ctx, CoreWidgetCtx(widgetHandle, tree[idParent]));
        final List<dynamic> array =
            (tree[idParent]!.param[id]) as List<dynamic>;
        trace('array=$array > ${widgetHandle.widgetValue}');
        array.add(widgetHandle.widgetValue);
      }
    }

    if (ctx.event!.action == 'browserAttr') {
      final String id = ctx.getPathData();
      trace('---> browserAttr <$id> ${ctx.event!.attr.type}');
      if (ctx.event!.attr.type == CDAttributType.CDmany) {
        dictionaryWidgets[ctx.event!.builder.name]
            ?.processProp(ctx, CoreWidgetCtx(tree[id]!, tree[idParent]));
      } else {
        dictionaryWidgets[ctx.event!.builder.name]
            ?.processProp(ctx, CoreWidgetCtx(tree[id]!, tree[idParent]));
      }
    }
  }
}
