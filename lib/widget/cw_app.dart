import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:xui_flutter/core/widget/cw_core_selector_overlay_action.dart';
import 'package:xui_flutter/designer/action_manager.dart';
import 'package:xui_flutter/designer/application_manager.dart';

import '../core/data/core_data.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_slot.dart';
import '../core/widget/cw_core_widget.dart';
import '../designer/builder/prop_builder.dart';
import '../core/widget/cw_factory.dart';
import '../designer/designer.dart';
import 'cw_app_router.dart';

final log = Logger('CWApp');

const String iDnbBtnBottomNavBar = '_nbBtnBottomNavBar_';

class CWAppInfo {
  double lastHeight = -1;
  double lastWidth = -1;

  void onChangePhysicalSize(CWApp widget) {
    if (widget.ctx.loader.mode == ModeRendering.design) {
      // double refresh car animation de resize par le composant Preview
      Future.delayed(const Duration(milliseconds: 100), () {
        CoreDesigner.emit(CDDesignEvent.reselect, null);
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        CoreDesigner.emit(CDDesignEvent.reselect, null);
      });
    }
  }

  void onChangeLogicalSize(CWApp widget) {
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
}

// ignore: must_be_immutable
class CWApp extends CWWidgetChild {
  CWApp({super.key, required super.ctx});

  static final CWAppInfo appInfo = CWAppInfo();

  final keySlotMain = GlobalKey(debugLabel: 'slot main');
  final rootMainKey = GlobalKey(debugLabel: 'rootMain');

  @override
  State<CWApp> createState() => _CWAppState();

  static void initFactory(CWWidgetCollectionBuilder c) {
    c
        .addWidget(
            'CWApp', (CWWidgetCtx ctx) => CWApp(key: ctx.getKey(), ctx: ctx))
        .addAttr('fill', CDAttributType.bool)
        .addAttr('color', CDAttributType.one, tname: 'color')
        .addAttr('dark', CDAttributType.bool)
        .addAttr('withBottomBar', CDAttributType.bool)
        .addAttr(iDnbBtnBottomNavBar, CDAttributType.int)
        .withAction(AttrActionDefault(0));

    c.collection
        .addObject('CWPageConstraint')
        .addAttr('nbAction', CDAttributType.int)
        .withAction(AttrActionDefault(0));
  }

  @override
  void initSlot(String path) {
    CWApplication.of().ctxApp = ctx;

    addSlotPath('root', SlotConfig('root'));

    var nb = nbBtnBottomNavBar();
    if (nb == 0) nb = 1;
    for (var i = 0; i < nb; i++) {
      addSlotPath('$path.Body$i',
          SlotConfig('${ctx.xid}Body$i', pathNested: '$path.AppBarAct$i'));
      addSlotPath('$path.Nav$i', SlotConfig('${ctx.xid}Nav$i'));
      addSlotPath('$path.AppBar$i',
          SlotConfig('${ctx.xid}AppBar$i', pathNested: '$path.AppBarAct$i'));

      var virtualCtx = createChildCtx(ctx, 'AppBarAct$i', null);
      addSlotPath(
          virtualCtx.pathWidget,
          SlotConfig(virtualCtx.xid,
              constraintEntity: 'CWPageConstraint',
              ctxVirtualSlot: virtualCtx));

      CWWidgetCtx? constraint =
          ctx.factory.mapConstraintByXid['${ctx.xid}AppBarAct$i'];
      int nb = constraint?.designEntity?.value['nbAction'] ?? 0;

      for (var j = 0; j < nb; j++) {
        addSlotPath(
            '$path.AppBarAct$i#$j',
            SlotConfig('${ctx.xid}AppBarAct$i#$j',
                pathNested: '$path.AppBarAct$i'));
      }
    }
  }

  bool isFill() {
    return ctx.designEntity!.getBool('fill', false);
  }

  bool isDark() {
    return ctx.designEntity!.getBool('dark', false);
  }

  int nbBtnBottomNavBar() {
    bool withBottom = ctx.designEntity!.getBool('withBottomBar', false);
    if (withBottom && ctx.designEntity!.value[iDnbBtnBottomNavBar] < 2) {
      CoreDataEntity prop =
          PropBuilder.preparePropChange(ctx.loader, DesignCtx().forDesign(ctx));
      prop.value[iDnbBtnBottomNavBar] = 2;
    } else if (!withBottom &&
        ctx.designEntity!.value[iDnbBtnBottomNavBar] > 0) {
      CoreDataEntity prop =
          PropBuilder.preparePropChange(ctx.loader, DesignCtx().forDesign(ctx));
      prop.value[iDnbBtnBottomNavBar] = 0;
    }

    return ctx.designEntity!.getInt(iDnbBtnBottomNavBar, 0)!;
  }

  final listRoute = <StatefulShellBranch>[];
  final listAction = <ActionLink>[];
  // todo A mettre dans le CWAppli
  static GoRouter? router;

  @override
  int getDefChild(String id) {
    if (id == iDnbBtnBottomNavBar) return 0;
    return 1;
  }
}

class _CWAppState extends StateCW<CWApp> with WidgetsBindingObserver {
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

  Color lightenOrDarken(bool dark, Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    HSLColor? hslColor;
    if (dark) {
      hslColor = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    } else {
      hslColor = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    }
    return hslColor.toColor();
  }

  Widget getRouterWithCache(BuildContext context) {
    var nbPage = widget.nbBtnBottomNavBar();
    if (nbPage == 0) nbPage = 1;

    Color mainColor = widget.getColor('color') ??
        (widget.isDark() ? Colors.grey.shade900 : Colors.white);
    //Color? backColor = widget.getColor('bgcolor');
    Color barForegorundColor = (mainColor.computeLuminance() > 0.400)
        ? lightenOrDarken(true, mainColor, 0.5) // dark
        : lightenOrDarken(false, mainColor, 0.5);

    var colorScheme2 = ColorScheme.fromSeed(
        seedColor: mainColor,
        brightness: widget.isDark() ? Brightness.dark : Brightness.light);

    var backgroundColor = colorScheme2.background;

    if (widget.listRoute.isEmpty || mustRepaint) {
      log.fine('create all routes');
      widget.listRoute.clear();
      for (var i = 0; i < nbPage; i++) {
        var aRoute = getSubRoute(i == 0 ? '/' : '/route$i', (state) {
          return getWidgetPage('route$i', backgroundColor);
        });

        widget.listRoute.add(aRoute);
      }
    }

    nbPage = widget.listAction.length;
    widget.listAction.clear();
    for (var i = 0; i < widget.nbBtnBottomNavBar(); i++) {
      widget.listAction
          .add(ActionLink('link $i', i == 0 ? '/' : '/route$i', widget.ctx));
    }

    //FocusScope.of(context).requestFocus(FocusNode());
    //*******************************************************************/

    if (routerWidgetCache == null ||
        CWApp.router == null ||
        widget.listAction.length != nbPage ||
        mustRepaint) {
      String r = '/';
      if (CWApp.router != null) {
        var l = CWApp.router!.routerDelegate.currentConfiguration.uri;
        r = l.path;
      }
      final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

      log.fine('create GoRouter instance');
      CWApp.router = GoRouter(
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
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        //showPerformanceOverlay: true,

        key: widget.rootMainKey,
        title: 'ElisView',
        routerConfig: CWApp.router,
        theme: ThemeData(
            scaffoldBackgroundColor: mainColor,
            appBarTheme: AppBarTheme(
              foregroundColor: barForegorundColor,
              backgroundColor: mainColor,
            ),
            //useMaterial3: true,
            colorScheme: colorScheme2),
        debugShowCheckedModeBanner: false,
        builder: DevicePreview.appBuilder,
        locale: DevicePreview.locale(context),
      );
    }

    mustRepaint = false;
    return routerWidgetCache!;
  }

  ScaffoldResponsiveDrawer getWidgetPage(String id, Color backgroundColor) {
    return ScaffoldResponsiveDrawer(
        appBar: AppBar(
          elevation: 0,
          title: getTitle(id),
          actions: getActions(id),
        ),
        body: ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            child: Container(
                color: backgroundColor, child: Material(child: getBody(id)))));
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

    // changemnt de la taille physical
    CWApp.appInfo.onChangePhysicalSize(widget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (CWApp.appInfo.lastHeight == -1) {
        CWApp.appInfo.lastHeight = constraints.maxHeight;
        CWApp.appInfo.lastWidth = constraints.maxWidth;
      }

      /*   controle d'ajustement de la taille */
      if (CWApp.appInfo.lastHeight != constraints.maxHeight ||
          CWApp.appInfo.lastWidth != constraints.maxWidth) {
        CWApp.appInfo.onChangeLogicalSize(widget);
        CWApp.appInfo.lastHeight = constraints.maxHeight;
        CWApp.appInfo.lastWidth = constraints.maxWidth;
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

  Widget getTitle(String idx) {
    return CWSlot(
        type: 'appbar',
        key: GlobalKey(debugLabel: 'slot appbar'),
        ctx: widget.createChildCtx(widget.ctx, 'AppBar$idx', null));
  }

  List<Widget> getActions(String idx) {
    var createChildCtx =
        widget.createChildCtx(widget.ctx, 'AppBarAct$idx', null);

    CWWidgetCtx? constraint =
        widget.ctx.factory.mapConstraintByXid[createChildCtx.xid];
    int nb = constraint?.designEntity?.value['nbAction'] ?? 0;

    List<Widget> ret = [];

    for (var i = 0; i < nb; i++) {
      ret.add(CWSlot(
          type: 'appbar',
          key: GlobalKey(debugLabel: 'slot appbar action'),
          ctx: widget.createChildCtx(widget.ctx, 'AppBarAct$idx#$i', null)));
    }

    // if (nb==0)
    // {
    //   ret.add(CWSlot(
    //       type: 'appbar',
    //       key: GlobalKey(debugLabel: 'slot appbar action'),
    //       ctx: widget.createChildCtx(widget.ctx, 'AppBarAct$idx', null)));
    // }

    return ret;
  }

  Widget getBody(String id) {
    if (widget.isFill()) {
      return Column(children: [
        Expanded(
            child: CWSlot(
                type: 'body',
                key: GlobalKey(debugLabel: 'slot body'),
                ctx: widget.createChildCtx(widget.ctx, 'Body$id', null),
                slotAction: SlotBodyAction()))
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
                  ctx: widget.createChildCtx(widget.ctx, 'Body$id', null),
                  slotAction: SlotBodyAction())
            ]),
          ));
    }
  }
}

class SlotBodyAction extends SlotAction {
  @override
  bool addBottom(CWWidgetCtx ctx) {
    DesignActionManager().doWrapWith(ctx, 'CWColumn', 'Cont0');
    return true;
  }

  @override
  bool addTop(CWWidgetCtx ctx) {
    DesignActionManager().doWrapWith(ctx, 'CWColumn', 'Cont1');
    return true;
  }

  @override
  bool canAddBottom() {
    return true;
  }

  @override
  bool canAddTop() {
    return true;
  }

  @override
  bool canDelete() {
    return false;
  }

  @override
  bool canMoveBottom() {
    return false;
  }

  @override
  bool canMoveTop() {
    return false;
  }

  @override
  bool moveBottom(CWWidgetCtx ctx) {
    return false;
  }

  @override
  bool moveTop(CWWidgetCtx ctx) {
    return false;
  }

  @override
  bool doDelete(CWWidgetCtx ctx) {
    return false;
  }

  @override
  bool addLeft(CWWidgetCtx ctx) {
    DesignActionManager().doWrapWith(ctx, 'CWRow', 'Cont1');
    return true;
  }

  @override
  bool addRight(CWWidgetCtx ctx) {
    DesignActionManager().doWrapWith(ctx, 'CWRow', 'Cont0');
    return true;
  }

  @override
  bool canAddLeft() {
    return true;
  }

  @override
  bool canAddRight() {
    return true;
  }

  @override
  bool canMoveLeft() {
    return false;
  }

  @override
  bool canMoveRight() {
    return false;
  }

  @override
  bool moveLeft(CWWidgetCtx ctx) {
    return false;
  }

  @override
  bool moveRight(CWWidgetCtx ctx) {
    return false;
  }
}
