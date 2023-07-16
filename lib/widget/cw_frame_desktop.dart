import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import '../core/widget/cw_core_slot.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/designer.dart';

class CWFrameDesktop extends CWWidget {
  CWFrameDesktop({super.key, required super.ctx});

  final keySlotMain = GlobalKey(debugLabel: "slot main");

  @override
  State<CWFrameDesktop> createState() => _CWFrameDesktop();

  @override
  initSlot(String path) {
    addSlotPath('root', SlotConfig('root'));
    addSlotPath('$path.Body', SlotConfig('${ctx.xid}Body'));
  }

  String getTitle() {
    return ctx.designEntity!.getString('title', def: '?')!;
  }

  bool isFill() {
    return ctx.designEntity!.getBool('fill', false);
  }
}

class _CWFrameDesktop extends StateCW<CWFrameDesktop>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    print("physical Size ${View.of(context).physicalSize}");
  }

  double lastHeight = -1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (lastHeight == -1) {
        lastHeight = constraints.maxHeight;
      }
      /*   controle d'ajustement de la taille */
      if (lastHeight != constraints.maxHeight) {
        Future.delayed(const Duration(milliseconds: 100), () {
          CoreDesigner.emit(CDDesignEvent.reselect, null);
        });
      }
      var slot = CWSlot(
          key: widget.keySlotMain,
          ctx: widget.ctx,
          childForced: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Mouse Region',
              builder: DevicePreview.appBuilder,
              locale: DevicePreview.locale(context),
              // theme: ThemeData.light(),
              // darkTheme: ThemeData.dark(),
              home: Scaffold(
                  appBar: AppBar(
                    title: Text(widget.getTitle()),
                  ),
                  body: getBody())));

      widget.ctx.inSlot = slot;
      return slot;
    });
  }

  Widget getBody() {
    if (widget.isFill()) {
      return Column(children: [
        Expanded(
            child: CWSlot(
                key: GlobalKey(debugLabel: "slot body"),
                ctx: widget.createChildCtx('Body', null)))
      ]);
    } else {
      return NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            print("onNotification $scrollNotification");
            return false;
          },
          child: SingleChildScrollView(
            child: Column(children: [
              CWSlot(
                  key: GlobalKey(debugLabel: "slot body"),
                  ctx: widget.createChildCtx('Body', null))
            ]),
          ));
    }
  }
}
