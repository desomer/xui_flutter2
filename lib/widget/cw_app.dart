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
const String iDnbBtnHeader = '_nbBtnHeader_';

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
class CWApp extends CWWidgetWithChild {
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
        .addAttr('color', CDAttributType.one, tname: 'color')
        .addAttr('dark', CDAttributType.bool)
        .addAttr('withBottomBar', CDAttributType.bool)
        .addAttr(iDnbBtnBottomNavBar, CDAttributType.int)
        .withAction(AttrActionDefault(0));

    c.collection
        .addObject('CWPageConstraint', label: 'Page constraint')
        .addAttr('fill', CDAttributType.bool)
        .withAction(AttrActionDefault(true))
        .addAttr(iDnbBtnHeader, CDAttributType.int)
        .withAction(AttrActionDefault(1));
  }

  @override
  void initSlot(String path, ModeParseSlot mode) {
    var app = CWApplication.of();
    app.ctxApp = ctx;

    addSlotPath('root', SlotConfig('root'), mode);

    var listPages = app.listPages;

    var nb = nbBtnBottomNavBar();
    for (var i = 0; i < nb; i++) {
      addSlotPath('$path.Nav$i', SlotConfig('${ctx.xid}Nav$i'), mode);
    }

    for (var i = 0; i < listPages.length; i++) {
      var id = 'Page${listPages[i].id}';
      addSlotPath('$path.Body$id',
          SlotConfig('${ctx.xid}Body$id', pathNested: '$path.Page$id'), mode);

      addSlotPath('$path.AppBar$id',
          SlotConfig('${ctx.xid}AppBar$id', pathNested: '$path.Page$id'), mode);

      var pageConstraint = createChildCtx(ctx, 'Page$id', null);
      addSlotPath(
          pageConstraint.pathWidget,
          SlotConfig(pageConstraint.xid,
              constraintEntity: 'CWPageConstraint', ctxVirtualSlot: pageConstraint),
          mode);

      CWWidgetCtx? constraint =
          ctx.factory.mapConstraintByXid['${ctx.xid}Page$id'];
      if (constraint != null) {
        constraint.pathWidget = pageConstraint.pathWidget;
      }

      int nb = constraint?.designEntity?.value[iDnbBtnHeader] ?? 1;
      if (nb == 0) nb = 1;
      // les slot d'action
      for (var j = 0; j < nb; j++) {
        addSlotPath(
            '$path.Page$id#$j',
            SlotConfig(
              '${ctx.xid}Page$id#$j',
              pathNested: '$path.Page$id',
            ),
            mode);
      }
    }
  }

  bool isFill(String idPage) {
    var ctxPage = createChildCtx(ctx, 'Page$idPage', null);
    CWWidgetCtx? constraintPage = ctx.factory.mapConstraintByXid[ctxPage.xid];

    return constraintPage?.designEntity?.getBool('fill', true) ?? true;
  }

  bool isDark() {
    return ctx.designEntity?.getBool('dark', false) ?? false;
  }

  int nbBtnBottomNavBar() {
    bool withBottom =
        ctx.designEntity?.getBool('withBottomBar', false) ?? false;
    int nbNav = ctx.designEntity?.value[iDnbBtnBottomNavBar] ?? 0;
    if (withBottom && nbNav < 2) {
      CoreDataEntity prop =
          PropBuilder.preparePropChange(ctx.loader, DesignCtx().forDesign(ctx));
      prop.value[iDnbBtnBottomNavBar] = 2;
      nbNav = 2;
    } else if (!withBottom && nbNav > 0) {
      CoreDataEntity prop =
          PropBuilder.preparePropChange(ctx.loader, DesignCtx().forDesign(ctx));
      prop.value[iDnbBtnBottomNavBar] = 0;
      nbNav = 0;
    }

    return nbNav;
  }

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
    var app = CWApplication.of();
    if (app.router == null) {
      app.initRoutePage();
      app.currentPage = app.listPages[0];
    }

    //var nbPage = widget.nbBtnBottomNavBar();
    //if (nbPage == 0) nbPage = 1;
    var listPages = app.listPages;
    var nbPage = listPages.length;

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

    if (app.listRoute.isEmpty || mustRepaint) {
      log.fine('create all routes');
      app.listRoute.clear();
      for (var i = 0; i < nbPage; i++) {
        var aRoute = getSubRoute(listPages[i].route, (state) {
          //'route${listPages[i].id}'
          return getWidgetPage('Page${listPages[i].id}', backgroundColor);
        });

        app.listRoute.add(aRoute);
      }
    }

    //nbPage = app.listAction.length;
    app.listAction.clear();
    for (var i = 0; i < widget.nbBtnBottomNavBar(); i++) {
      app.listAction.add(ActionLink('id$i', '${widget.ctx.xid}Nav$i',
          i == 0 ? '/' : '/route$i', widget.ctx));
    }

    //FocusScope.of(context).requestFocus(FocusNode());
    //*******************************************************************/

    if (routerWidgetCache == null || app.router == null || mustRepaint) {
      String r = '/';
      if (app.router != null) {
        var l = app.router!.routerDelegate.currentConfiguration.uri;
        r = l.path;
      }

      final rootNavigatorKey =
          GlobalKey<NavigatorState>(debugLabel: 'rootNavigatorState');

      log.fine('create GoRouter instance');
      app.router = GoRouter(
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
                      listAction: app.listAction,
                      navigationShell: navigationShell,
                      children: children);
                },
                branches: app.listRoute)
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
        routerConfig: app.router,

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

  ScaffoldResponsiveDrawer getWidgetPage(String idPage, Color backgroundColor) {
    return ScaffoldResponsiveDrawer(
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: true,
          title: getTitle(idPage),
          actions: getActions(idPage),
        ),
        body: ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            child: Container(
                color: backgroundColor,
                child: Material(child: getBody(idPage)))));
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

  Widget getTitle(String id) {
    return CWSlot(
        type: 'appbar',
        key: GlobalKey(debugLabel: 'slot appbar'),
        ctx: widget.createChildCtx(widget.ctx, 'AppBar$id', null));
  }

  List<Widget> getActions(String idPage) {
    var createChildCtx = widget.createChildCtx(widget.ctx, 'Page$idPage', null);

    CWWidgetCtx? constraintPage =
        widget.ctx.factory.mapConstraintByXid[createChildCtx.xid];

    int nbAction = constraintPage?.designEntity?.value[iDnbBtnHeader] ?? 1;
    if (nbAction == 0) nbAction = 1;

    List<Widget> ret = [];

    for (var i = 0; i < nbAction; i++) {
      ret.add(CWSlot(
          type: 'appbar',
          key: GlobalKey(debugLabel: 'slot appbar action'),
          ctx: widget.createChildCtx(widget.ctx, 'Page$idPage#$i', null),
          slotAction: SlotNavAction('Page$idPage#', iDnbBtnHeader,
              ctxConstraint: constraintPage ?? createChildCtx)));
    }

    // if (nb==0)
    // {
    //   ret.add(CWSlot(
    //       type: 'appbar',
    //       key: GlobalKey(debugLabel: 'slot appbar action'),
    //       ctx: widget.createChildCtx(widget.ctx, 'Page$idx', null)));
    // }

    return ret;
  }

  Widget getBody(String idPage) {
    if (widget.isFill(idPage)) {
      return Column(children: [
        Expanded(
            child: CWSlot(
                type: 'body',
                key: GlobalKey(debugLabel: 'slot body'),
                ctx: widget.createChildCtx(widget.ctx, 'Body$idPage', null),
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
                  ctx: widget.createChildCtx(widget.ctx, 'Body$idPage', null),
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
