import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:xui_flutter/core/widget/cw_core_selector_overlay_action.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_slot.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/cw_factory.dart';
import '../designer/designer.dart';
import 'cw_router.dart';

final log = Logger('CWFrameDesktop');

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
        .addAttr('color', CDAttributType.one, tname: 'color')
        .addAttr('dark', CDAttributType.bool)
        //.addAttr('bgcolor', CDAttributType.one, tname: 'color')
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

  Color? getColor(String id) {
    String? v = ctx.designEntity!.value[id]?['color'];
    return v != null ? Color(int.parse(v, radix: 16)) : null;
  }

  bool isFill() {
    return ctx.designEntity!.getBool('fill', false);
  }

  bool isDark() {
    return ctx.designEntity!.getBool('dark', false);
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
        builder: (context, state) {
          return fct(state);
        },
      )
    ]);
  }

  Widget getRouterWithCache(BuildContext context) {
    var nb = widget.nbBtnBottomNavBar();
    if (nb == 0) nb = 1;

    Color mainColor = widget.getColor('color') ?? Colors.white;
    //Color? backColor = widget.getColor('bgcolor');
    Color barForegorundColor =
        (mainColor.computeLuminance() > 0.300) ? Colors.black : Colors.white;

    var colorScheme2 = ColorScheme.fromSeed(
        seedColor: mainColor,
        brightness: widget.isDark() ? Brightness.dark : Brightness.light);

    var backgroundColor = colorScheme2.background;

    if (widget.listRoute.isEmpty || mustRepaint) {
      log.fine('create all routes');
      widget.listRoute.clear();
      for (var i = 0; i < nb; i++) {
        var aRoute = getSubRoute(i == 0 ? '/' : '/route$i', (state) {
          return ScaffoldResponsiveDrawer(
              appBar: AppBar(elevation: 0, title: getTitle(i)),
              body: ClipRRect(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                  child: Container(color: backgroundColor, child: getBody(i))));
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

    if (routerWidgetCache == null ||
        CWFrameDesktop.router == null ||
        widget.listAction.length != nb ||
        mustRepaint) {
      String r = '/';
      if (CWFrameDesktop.router != null) {
        var l = CWFrameDesktop.router!.routerDelegate.currentConfiguration.uri;
        r = l.path;
      }
      final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
      log.fine('create GoRouter instance');
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
        title: 'ElisView',
        routerConfig: CWFrameDesktop.router,
        theme: ThemeData(
            scaffoldBackgroundColor: mainColor,
            appBarTheme: AppBarTheme(
              foregroundColor: barForegorundColor,
              backgroundColor: mainColor,
            ),
            useMaterial3: true,
            colorScheme: colorScheme2),
        debugShowCheckedModeBanner: false,
        builder: DevicePreview.appBuilder,
        locale: DevicePreview.locale(context),
      );
    }

    mustRepaint = false;
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
    //debugPrint('physical Size ${View.of(context).physicalSize}');

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

      Widget aFrame = getRouterWithCache(context);

      var slot = CWSlot(
          type: 'root',
          key: widget.keySlotMain,
          ctx: widget.ctx,
          childForced: aFrame);

      widget.ctx.inSlot = slot;
      return slot;
    });
  }

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
