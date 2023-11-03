import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xui_flutter/core/widget/cw_core_selector_overlay_action.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_slot.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/cw_factory.dart';
import '../designer/designer.dart';
import 'cw_router.dart';

// ignore: must_be_immutable
class CWFrameDesktop extends CWWidget {
  CWFrameDesktop({super.key, required super.ctx});

  final keySlotMain = GlobalKey(debugLabel: 'slot main');
  final rootMainKey = GlobalKey(debugLabel: 'rootMain');

  @override
  State<CWFrameDesktop> createState() => _CWFrameDesktop();

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget('CWFrameDesktop',
            (CWWidgetCtx ctx) => CWFrameDesktop(key: ctx.getKey(), ctx: ctx))
        .addAttr('fill', CDAttributType.bool)
        .addAttr('nbBtnBottomNavBar', CDAttributType.int)
        .withAction(AttrActionDefault(0));

    // c.collection
    //     .addObject('CWRouteConstraint')
    //     .addAttr('title', CDAttributType.text);
  }

  @override
  void initSlot(String path) {
    addSlotPath('root', SlotConfig('root'));
    var nb = nbBtnBottomNavBar();
    if (nb == 0) nb = 1;
    for (var i = 0; i < nb; i++) {
      addSlotPath(
          '$path.Body$i',
          SlotConfig(
            '${ctx.xid}Body$i',
            //constraintEntity: 'CWRouteConstraint'
          ));
      addSlotPath('$path.Btn$i', SlotConfig('${ctx.xid}Btn$i'));
      addSlotPath('$path.AppBar$i', SlotConfig('${ctx.xid}AppBar$i')); 
    }
  }

  // String getTitle() {
  //   return ctx.designEntity!.getString('title', def: '?')!;
  // }

  bool isFill() {
    return ctx.designEntity!.getBool('fill', false);
  }

  int nbBtnBottomNavBar() {
    return ctx.designEntity!.getInt('nbBtnBottomNavBar', 0);
  }

  final listRoute = <StatefulShellBranch>[];
  final listAction = <ActionLink>[];
  // todo A mettre dans le CWAppli
  static GoRouter? router;
}

class _CWFrameDesktop extends StateCW<CWFrameDesktop>
    with WidgetsBindingObserver {
  //////////////////////////////////////////////////////////////////////////
  Widget? routerWidgetCache;

  StatefulShellBranch getSubRoute(String path, Function(GoRouterState) fct) {
    return StatefulShellBranch(routes: <RouteBase>[
      GoRoute(
        path: path,
        //pageBuilder : animPageBuilder(fct)
        builder: (context, state) {
          return fct(state);
        },
      )
    ]);
  }

  Widget getRouter(BuildContext context) {
    var nb = widget.nbBtnBottomNavBar();
    if (nb == 0) nb = 1;
    if (widget.listRoute.isEmpty || widget.listRoute.length != nb) {
      debugPrint('create route');
      widget.listRoute.clear();
      for (var i = 0; i < nb; i++) {
        var aRoute = getSubRoute(i == 0 ? '/' : '/route$i', (state) {
          // CWWidgetCtx? constraint =
          //     widget.ctx.factory.mapConstraintByXid['${widget.ctx.xid}Body$i'];
          // //print("getCell -------- ${slot.ctx.xid} $constraint");
          // String title = constraint?.designEntity?.value['title'] ?? 'none';

          return ScaffoldResponsiveDrawer(
              appBar: AppBar(elevation: 0, title: getTitle(i)),
              body: ClipRRect(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                  child: Container(color: Colors.white, child: getBody(i))));
        });
        widget.listRoute.add(aRoute);
      }
    }

    nb = widget.listAction.length;
    widget.listAction.clear();
    for (var i = 0; i < widget.nbBtnBottomNavBar(); i++) {
      widget.listAction.add(ActionLink('link $i', Icons.link, widget.ctx));
    }

    //FocusScope.of(context).requestFocus(FocusNode());
    //*******************************************************************/

    if (routerWidgetCache ==null || CWFrameDesktop.router == null || widget.listAction.length != nb) {
      String r = '/';
      if (CWFrameDesktop.router != null) {
        var l = CWFrameDesktop.router!.routerDelegate.currentConfiguration.uri;
        r = l.path;
      }
      final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
      debugPrint('create go router');
      CWFrameDesktop.router = GoRouter(
          navigatorKey: rootNavigatorKey,
          initialLocation: r,
          routes: <RouteBase>[
            StatefulShellRoute(
                builder: (BuildContext context, GoRouterState state,
                    StatefulNavigationShell navigationShell) {
                  return navigationShell;
                },
                navigatorContainerBuilder: (BuildContext context,
                    StatefulNavigationShell navigationShell,
                    List<Widget> children) {
                  return ScaffoldWithNestedNavigation(
                      listAction: widget.listAction,
                      navigationShell: navigationShell,
                      children: children);
                },
                branches: widget.listRoute)
          ]);

      routerWidgetCache = MaterialApp.router(
        key: widget.rootMainKey,
        title: 'Flutter Demo',
        routerConfig: CWFrameDesktop.router,
        theme: ThemeData().copyWith(scaffoldBackgroundColor: Colors.blue),
        debugShowCheckedModeBanner: false,
        builder: DevicePreview.appBuilder,
        locale: DevicePreview.locale(context),
      );
    }

    return routerWidgetCache!;
  }

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
    debugPrint('physical Size ${View.of(context).physicalSize}');
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

      // Widget aFrame = MaterialApp(
      //     theme: ThemeData().copyWith(scaffoldBackgroundColor: Colors.blue),
      //     debugShowCheckedModeBanner: false,
      //     title: 'ElisView',
      //     builder: DevicePreview.appBuilder,
      //     locale: DevicePreview.locale(context),
      //     // theme: ThemeData.light(),
      //     // darkTheme: ThemeData.dark(),
      //     home: Scaffold(
      //         appBar: AppBar(
      //           backgroundColor: Colors.blue,
      //           elevation: 0,
      //           leading: const Icon(Icons.menu),
      //           title: Text(widget.getTitle()),
      //           actions: [
      //             // Icon(Icons.favorite),
      //             // Padding(
      //             //   padding: EdgeInsets.symmetric(horizontal: 16),
      //             //   child: Icon(Icons.search),
      //             // ),
      //             IconButton(
      //               icon: const Icon(Icons.more_vert),
      //               onPressed: () {},
      //             ),
      //           ],
      //         ),
      //         body: ClipRRect(
      //             borderRadius: const BorderRadius.only(
      //                 topLeft: Radius.circular(20),
      //                 topRight: Radius.circular(20)),
      //             child: Container(color: Colors.white, child: getBody())),
      //         bottomNavigationBar: getBottomBar(context)));

      //Widget aFrame  = CwRouter(body: getBody());
      Widget aFrame = getRouter(context);

      var slot = CWSlot(
          type: 'root',
          key: widget.keySlotMain,
          ctx: widget.ctx,
          childForced: aFrame);

      widget.ctx.inSlot = slot;
      return slot;
    });
  }

  // MediaQuery? getBottomBar(BuildContext context) {
  //   var bottomBar = getBottomNavigation();
  //   if (bottomBar == null) return null;
  //   return MediaQuery(
  //     data: MediaQuery.of(context).removePadding(removeBottom: true),
  //     child: bottomBar,
  //   );
  // }

  // BottomNavigationBar? getBottomNavigation() {
  //   if (widget.nbBtnBottomNavBar() < 2) return null;

  //   List<BottomNavigationBarItem> listBtn = [];
  //   for (var i = 0; i < widget.nbBtnBottomNavBar(); i++) {
  //     listBtn.add(const BottomNavigationBarItem(
  //       label: 'Home',
  //       icon: Icon(Icons.home),
  //     ));
  //   }

  //   return BottomNavigationBar(
  //       currentIndex: 0,
  //       //fixedColor: Colors.green,
  //       items: listBtn,
  //       type: BottomNavigationBarType.fixed,
  //       onTap: (int indexOfItem) {});
  // }

  Widget getTitle(int idx) {
    return CWSlot(
        type: 'appbar',
        key: GlobalKey(debugLabel: 'slot appbar'),
        ctx: widget.createChildCtx(widget.ctx, 'AppBar$idx', null));
  }

  Widget getBody(int idx) {
    if (widget.isFill()) {
      return Column(children: [
        Expanded(
            child: CWSlot(
                type: 'body',
                key: GlobalKey(debugLabel: 'slot body'),
                ctx: widget.createChildCtx(widget.ctx, 'Body$idx', null)))
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
                  type: 'body',
                  key: GlobalKey(debugLabel: 'slot body'),
                  ctx: widget.createChildCtx(widget.ctx, 'Body$idx', null))
            ]),
          ));
    }
  }
}
