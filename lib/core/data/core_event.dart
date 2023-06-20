import 'core_data.dart';

class CoreBrowseEventHandler {
  void process(CoreDataCtx ctx) {
    if (ctx.event!.action.startsWith('browserObject')) {
      doTrace(
          '${ctx.event!.action} [${ctx.event!.builder.name}] ${ctx.getPathData()} = ${ctx.event!.src}');
    } else if (ctx.event!.action == 'browserAttr') {
      doTrace(
          '${ctx.event!.action} [${ctx.event!.builder.name}] ${ctx.getPathData()}.${ctx.event!.attr.name} = ${ctx.event!.value}');
    }
  }

  void doTrace(String str) {
    // ignore: avoid_print
    print('>>>>> browse >>>>>> $str');
  }
}
