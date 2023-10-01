import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_selector_overlay_action.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_slot.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/cw_factory.dart';
import '../designer/designer.dart';

class CWFrameDesktop extends CWWidget {
  CWFrameDesktop({super.key, required super.ctx});

  final keySlotMain = GlobalKey(debugLabel: "slot main");

  @override
  State<CWFrameDesktop> createState() => _CWFrameDesktop();

  static initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget("CWFrameDesktop",
            (CWWidgetCtx ctx) => CWFrameDesktop(key: ctx.getKey(), ctx: ctx))
        .addAttr('title', CDAttributType.text)
        .addAttr('fill', CDAttributType.bool)
        .addAttr('nbBtnBottomNavBar', CDAttributType.int)
        .withAction(AttrActionDefault(0));
  }

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

  int nbBtnBottomNavBar() {
    return ctx.designEntity!.getInt('nbBtnBottomNavBar', 0);
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
    debugPrint("physical Size ${View.of(context).physicalSize}");
    if (widget.ctx.loader.mode == ModeRendering.design) {
      // double refresh car animation de resize par le composant Preview
      Future.delayed(const Duration(milliseconds: 50), () {
        CoreDesigner.emit(CDDesignEvent.reselect, null);
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        CoreDesigner.emit(CDDesignEvent.reselect, null);
      });
    }
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
        if (widget.ctx.loader.mode == ModeRendering.design) {
          // double refresh car animation de resize par le composant Preview
          Future.delayed(const Duration(milliseconds: 50), () {
            CoreDesigner.emit(CDDesignEvent.reselect, null);
          });
          Future.delayed(const Duration(milliseconds: 300), () {
            CoreDesigner.emit(CDDesignEvent.reselect, null);
          });
        }
        lastHeight = constraints.maxHeight;
      }

      var slot = CWSlot(
          type: "root",
          key: widget.keySlotMain,
          ctx: widget.ctx,
          childForced: MaterialApp(
              theme: ThemeData().copyWith(scaffoldBackgroundColor: Colors.blue),
              debugShowCheckedModeBanner: false,
              title: 'ElisView',
              builder: DevicePreview.appBuilder,
              locale: DevicePreview.locale(context),
              // theme: ThemeData.light(),
              // darkTheme: ThemeData.dark(),
              home: Scaffold(
                  appBar: AppBar(
                    backgroundColor: Colors.blue,
                    elevation: 0,
                    leading: const Icon(Icons.menu),
                    title: Text(widget.getTitle()),
                    actions: [
                      // Icon(Icons.favorite),
                      // Padding(
                      //   padding: EdgeInsets.symmetric(horizontal: 16),
                      //   child: Icon(Icons.search),
                      // ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  body: ClipRRect(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20)),
                      child: Container(color: Colors.white, child: getBody())),
                  bottomNavigationBar: getBottomBar(context))));

      widget.ctx.inSlot = slot;
      return slot;
    });
  }

  MediaQuery? getBottomBar(BuildContext context) {
    var bottomBar = getBottomNavigation();
    if (bottomBar == null) return null;
    return MediaQuery(
      data: MediaQuery.of(context).removePadding(removeBottom: true),
      child: bottomBar,
    );
  }

  BottomNavigationBar? getBottomNavigation() {
    if (widget.nbBtnBottomNavBar() < 2) return null;

    List<BottomNavigationBarItem> listBtn = [];
    for (var i = 0; i < widget.nbBtnBottomNavBar(); i++) {
      listBtn.add(const BottomNavigationBarItem(
        label: "Home",
        icon: Icon(Icons.home),
      ));
    }

    return BottomNavigationBar(
        currentIndex: 0,
        //fixedColor: Colors.green,
        items: listBtn,
        type: BottomNavigationBarType.fixed,
        onTap: (int indexOfItem) {});
  }

  Widget getBody() {
    if (widget.isFill()) {
      return Column(children: [
        Expanded(
            child: CWSlot(
                type: "body",
                key: GlobalKey(debugLabel: "slot body"),
                ctx: widget.createChildCtx('Body', null)))
      ]);
    } else {
      return NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            //debugPrint("onNotification $scrollNotification");
            SelectorActionWidget.removeActionWidget();
            return false;
          },
          child: SingleChildScrollView(
            child: Column(children: [
              CWSlot(
                  type: "body",
                  key: GlobalKey(debugLabel: "slot body"),
                  ctx: widget.createChildCtx('Body', null))
            ]),
          ));
    }
  }
}
