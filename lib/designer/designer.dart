import 'dart:async';

import 'package:event_listener/event_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/designer/designer_pages.dart';
import 'package:xui_flutter/designer/widget_component.dart';
import 'package:xui_flutter/designer/widget_debug.dart';
import 'package:xui_flutter/designer/widget_drag_file.dart';
import 'package:xui_flutter/designer/widget_tab.dart';
import 'package:xui_flutter/widget/cw_breadcrumb.dart';

import '../core/store/driver.dart';
import '../db_icon_icons.dart';
import '../widget/cw_dialog.dart';
import '../widget/cw_image.dart';
import 'cw_factory.dart';
import 'designer_attribut.dart';
import 'designer_data.dart';
import 'designer_model.dart';
import 'designer_query.dart';
import 'designer_view.dart';
import 'help/widget_hidden_box.dart';
import 'widget/widget_preview.dart';
import 'widget_model_attribut.dart';
import 'widget_properties.dart';
import 'widget_filter_builder.dart';

enum CDDesignEvent { select, reselect, preview, save }

// ignore: must_be_immutable
class CoreDesigner extends StatefulWidget {
  CoreDesigner({super.key}) {
    designView = DesignerView(key: designerKey);
    _coreDesigner = this;
    CoreDesigner.on(CDDesignEvent.save, (arg) async {
      debugPrint('save action');
      StoreDriver? storage = await StoreDriver.getDefautDriver('main');
      storage?.setData('#pages', CoreDesigner.ofLoader().cwFactory.value);
    });
  }

  static Function(dynamic) on(CDDesignEvent event, Function(dynamic) fct) {
    of()._eventListener.on(event.toString(), fct);
    return fct;
  }

  static void emit(CDDesignEvent event, dynamic payload) {
    of()._eventListener.emit(event.toString(), payload);
  }

  static void removeListener(CDDesignEvent event, Function(dynamic) fct) {
    of()._eventListener.removeEventListener(event.toString(), fct);
  }

  static CoreDesigner of() {
    return _coreDesigner;
  }

  static DesignerView ofView() {
    return _coreDesigner.designView;
  }

  static CWWidgetLoader ofLoader() {
    return _coreDesigner.designView.loader!;
  }

  static WidgetFactoryEventHandler ofFactory() {
    return ofLoader().ctxLoader.factory;
  }

  static late CoreDesigner _coreDesigner;
  late DesignerView designView;

  final GlobalKey imageKey = GlobalKey(debugLabel: 'CoreDesigner.imageKey');
  final GlobalKey rootKey = GlobalKey(debugLabel: 'rootKey');
  final GlobalKey designerKey =
      GlobalKey(debugLabel: 'CoreDesignerdesignerKey');
  final GlobalKey propKey = GlobalKey(debugLabel: 'CoreDesigner.propKey');

  final GlobalKey dataKey = GlobalKey(debugLabel: 'CoreDesigner.dataKey');
  final GlobalKey dataFilterKey =
      GlobalKey(debugLabel: 'CoreDesigner.dataFilterKey');

  final _eventListener = EventListener();
  late TabController controllerTabRight;

  final ScrollController scrollComponentController = ScrollController(
    initialScrollOffset: 0.0,
    keepScrollOffset: true,
  );

  final ScrollController scrollPropertiesController = ScrollController(
    initialScrollOffset: 0.0,
    keepScrollOffset: true,
  );

  @override
  State<CoreDesigner> createState() => _CoreDesignerState();
}

class RouteTest extends Route {
  RouteTest({super.settings});
}

class _CoreDesignerState extends State<CoreDesigner>
    with SingleTickerProviderStateMixin {
  final PageStorageBucket _bucket = PageStorageBucket();

  final clipboardcontentstream = StreamController<String>.broadcast();
  Timer? clipboardtriggertime;
  Stream get clipboardtext => clipboardcontentstream.stream;

  @override
  void initState() {
    super.initState();

    // clipboardtriggertime = Timer.periodic(
    //   const Duration(seconds: 5),
    //   (timer) {
    //     Clipboard.getData('text/plain').then((clipboarcontent) {
    //       if (clipboarcontent != null) {
    //         print('clipboard content ${clipboarcontent.text}');
    //         clipboardcontentstream.add(clipboarcontent.text!);
    //       }
    //     });
    //   },
    // );
  }

  @override
  void dispose() {
    super.dispose();
    clipboardcontentstream.close();
    clipboardtriggertime?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final NavRail nav = NavRail();
    nav.listTabNav = [
      getDesignPan(),
      getDataPan(),
      getQueryPan(),
      getDebugPan(),
      getTestPan()
    ];

    List<Route> currentRouteStack = [];
    currentRouteStack
        .add(RouteTest(settings: const RouteSettings(name: 'Root')));
    currentRouteStack
        .add(RouteTest(settings: const RouteSettings(name: 'Text')));

    return MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // supportedLocales: const [
        //   Locale('en'),
        //   Locale('fr')
        // ],
        // localeResolutionCallback:
        //     (Locale? locale, Iterable<Locale> supportedLocales) {
        //   for (Locale supportedLocale in supportedLocales) {
        //     if (kIsWeb) {
        //       Locale webLocale = Locale(ui.window.locale.languageCode, '');
        //       print('system locale is ${webLocale}');
        //       return webLocale;
        //     } else if (supportedLocale.languageCode == locale!.languageCode ||
        //         supportedLocale.countryCode == locale.countryCode) {
        //       print('device Locale is $locale');
        //       return supportedLocale;
        //     }
        //   }
        //   return supportedLocales.first;
        // },
        key: CoreDesigner.of().rootKey,
        debugShowCheckedModeBanner: false,
        title: 'ElisView',
        theme: ThemeData(
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // standard dark theme
        darkTheme: ThemeData.dark().copyWith(
            indicatorColor: Colors.amber,
            inputDecorationTheme: const InputDecorationTheme(
                labelStyle: TextStyle(color: Colors.white70))),
        //themeMode: ThemeMode.system,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          appBar: AppBar(
            title: Row(
                // color: Colors.blue.withOpacity(0.3),
                children: [
                  BreadCrumbNavigator(currentRouteStack),
                  const Spacer(),
                  const WidgetPreview(),
                  InkWell(
                    child: const Icon(size: 25, Icons.save),
                    onTap: () {
                      CoreDesigner.emit(CDDesignEvent.save, null);
                    },
                  ),
                  const SizedBox(width: 20),
                  const Text('ElisView v0.4.1'),
                  const SizedBox(width: 5),
                  IconButton(
                    iconSize: 30,
                    icon: const Icon(Icons.apps),
                    onPressed: () {},
                  )
                ]),
          ),
          body: PageStorage(bucket: _bucket, child: nav),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.miniCenterDocked,
          floatingActionButton: FloatingActionButton(
            elevation: 4,
            backgroundColor: Colors.deepOrange.shade400,
            mini: true,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              widget.controllerTabRight.index = 1;
            },
          ),
          bottomNavigationBar: BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 4.0,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.undo),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.redo),
                      onPressed: () {},
                    ),
                    Tooltip(
                        message: 'Clear all',
                        child: IconButton(
                          icon: const Icon(Icons.clear_all),
                          onPressed: () {},
                        )),
                  ]),
                  const Spacer(),
                  const Text('Desomer G.  02/11/23'),
                  IconButton(
                    icon: const Icon(Icons.help),
                    onPressed: () {},
                  ),
                ],
              )),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Text('Entete du Drawer'),
                ),
                ListTile(
                  title: const Text('Item 1'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Item 2'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ));
  }

  Widget getQueryPan() {
    CWWidgetCtx ctx = CWWidgetCtx('', CWApplication.of().loaderModel, '');
    ctx.designEntity = CWApplication.of()
        .loaderModel
        .collectionWidget
        .createEntityByJson('CWArray', {'providerName': 'DataModelProvider'});

    return Row(
      children: [SizedBox(width: 300, child: DesignerQuery(ctx: ctx))],
    );
  }

  Widget getDataPan() {
    var viewAttribute = Container(
      color: Colors.black26,
      child: Stack(
        children: [
          Positioned(
              left: 20,
              top: 20,
              width: 300,
              child: Container(
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: const DesignerModel()))
        ],
      ),
    );

    var rainboxBox = Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            offset: Offset(-20, 20),
            color: Colors.red,
            blurRadius: 15,
            spreadRadius: -10,
          ),
          BoxShadow(
            offset: Offset(-20, -20),
            color: Colors.orange,
            blurRadius: 15,
            spreadRadius: -10,
          ),
          BoxShadow(
            offset: Offset(20, -20),
            color: Colors.blue,
            blurRadius: 15,
            spreadRadius: -10,
          ),
          BoxShadow(
            offset: Offset(25, 25),
            color: Colors.deepPurple,
            blurRadius: 15,
            spreadRadius: -10,
          )
        ],
        //color: Colors.grey.shade800
      ),
      child: Card(
        color: Colors.grey.shade800,
        elevation: 3,
      ),
    );

    WidgetTab tabAttributDesc = WidgetTab(heightTab: 30, listTab: const [
      Tab(text: 'Properties'),
      Tab(text: 'Validator'),
      Tab(text: 'Style')
    ], listTabCont: [
      Row(
        children: [const Expanded(child: DesignerAttribut()), rainboxBox],
      ),
      Container(),
      Container()
    ]);

    WidgetTab tabModelDesc = WidgetTab(
      heightTab: 60,
      listTab: const [
        Tab(text: 'Model', icon: Icon(Icons.data_object)),
        Tab(text: 'Data', icon: Icon(Icons.table_chart))
      ],
      listTabCont: [
        Column(children: [
          Expanded(
              child: Row(
            children: [
              Expanded(
                  child: Column(
                children: [
                  Expanded(child: viewAttribute), // les attributs
                  WidgetHiddenBox(child: tabAttributDesc)
                ],
              )), // ),
              SizedBox(
                // les type d'attribut
                width: 300,
                child: Column(children: AttributDesc.getListAttr),
              )
            ],
          )),
          //
        ]),
        Column(
          children: [
            WidgetFilterbuilder(
                key: widget.dataFilterKey, filter: CoreDataFilter()),
            Expanded(child: DesignerData(key: widget.dataKey))
          ],
        )
      ],
    );

    return Row(
      children: [
        const SizedBox(
          width: 200,
          child: DesignerListModel(),
        ),
        Expanded(child: tabModelDesc)
      ],
    );
  }

  Widget getDebugPan() {
    return const WidgetDebug();
  }

  Widget getTestPan() {
    return SingleChildScrollView(
        child: Column(children: [
      Image.network('https://googleflutter.com/sample_image.jpg', width: 200),
      const WidgetDragTarget(),
      const DialogExample(key: PageStorageKey<String>('pageMain')),
      CwImage(key: CoreDesigner.of().imageKey),
      MaterialColorPicker(
          onColorChange: (Color color) {
            debugPrint(color.toString());
          },
          onMainColorChange: (ColorSwatch<dynamic>? color) {
            debugPrint(color!.value.toString());
          },
          selectedColor: Colors.red)
    ]));
  }

  Widget getDesignPan() {
    CWWidgetCtx ctxQuery = CWWidgetCtx('', CWApplication.of().loaderModel, '');
    ctxQuery.designEntity = CWApplication.of()
        .loaderModel
        .collectionWidget
        .createEntityByJson('CWArray', {'providerName': 'DataModelProvider'});

    CWWidgetCtx ctxPages = CWWidgetCtx('', CWApplication.of().loaderModel, '');
    ctxPages.designEntity = CWApplication.of()
        .loaderModel
        .collectionWidget
        .createEntityByJson('CWArray', {'providerName': 'PagesProvider'});

    return Row(children: [
      SizedBox(
        width: 300,
        child: WidgetTab(heightTab: 40, listTab: const [
          Tab(icon: Tooltip(message: 'Navigation', child: Icon(Icons.near_me))),
          Tab(icon: Tooltip(message: 'Data', child: Icon(Icons.filter_alt)))
        ], listTabCont: [
          DesignerPages(ctx: ctxPages),
          DesignerQuery(ctx: ctxQuery)
        ]),
      ),
      Expanded(child: widget.designView),
      SizedBox(
          //  margin: new EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
          width: 300,
          child: getTabProperties())
    ]);
    // return SplitPane(
    //     child1: getDesignerBody(),
    //     child2: Container(
    //       color: Colors.red,
    //       width: 300,
    //     ));
  }

  Widget getTabProperties() {
    final List<Widget> listTab = <Widget>[];
    listTab.add(const Tab(
      // height: 30,
      icon: Icon(Icons.edit_note),
    ));

    listTab.add(const Tab(
      // height: 30,
      icon: Icon(Icons.widgets),
    ));

    final List<Widget> listTabCont = <Widget>[];

    listTabCont.add(SingleChildScrollView(
        key: const PageStorageKey<String>('pageProp'),
        controller: widget.scrollPropertiesController,
        scrollDirection: Axis.vertical,
        child: DesignerProp(key: CoreDesigner.of().propKey)));

    listTabCont.add(SingleChildScrollView(
        key: const PageStorageKey<String>('pageWidget'),
        controller: widget.scrollComponentController,
        scrollDirection: Axis.vertical,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ComponentDesc.getListComponent))); // const Steps());

    return WidgetTab(
        heightTab: 40,
        onController: (TabController a) {
          widget.controllerTabRight = a;
        },
        listTab: listTab,
        listTabCont: listTabCont);
  }
}
/////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
// ignore: must_be_immutable
class NavRail extends StatefulWidget {
  NavRail({super.key});

  late List<Widget> listTabNav;

  @override
  State<NavRail> createState() => _NavRailState();
}

class _NavRailState extends State<NavRail> {
  int selectedIndex = 0;

  PageController pageController = PageController();

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        NavigationRail(
          minWidth: 40,
          labelType: NavigationRailLabelType.none,
          selectedIconTheme: const IconThemeData(color: Colors.deepOrange),
          // unselectedIconTheme: const IconThemeData(color: Colors.blueGrey),
          // selectedLabelTextStyle: const TextStyle(color: Colors.green),
          // unselectedLabelTextStyle: const TextStyle(color: Colors.blueGrey),
          selectedIndex: selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              selectedIndex = index;
              pageController.jumpToPage(index);

              // pageController.animateToPage(index,
              //     duration: const Duration(milliseconds: 200),
              //     curve: Curves.easeIn);
            });
          },
          destinations: const <NavigationRailDestination>[
            NavigationRailDestination(
              icon: Tooltip(
                  message: 'Edit Pages', child: Icon(Icons.edit_document)),
              label: Text('Edit'),
            ),
            NavigationRailDestination(
              icon: Tooltip(
                  message: 'Data', child: Icon(size: 18, DBIcon.database)),
              label: Text('Store'),
            ),
            NavigationRailDestination(
              icon: Tooltip(message: 'Query', child: Icon(Icons.filter_alt)),
              label: Text('Query'),
            ),
            NavigationRailDestination(
              icon: Tooltip(message: 'Debug', child: Icon(Icons.bug_report)),
              label: Text('Debug'),
            ),
            NavigationRailDestination(
              icon: Tooltip(message: 'Test', child: Icon(Icons.quiz)),
              label: Text('Test'),
            ),
          ],
        ),
        Expanded(
            child: PageView(
          controller: pageController,
          children: widget.listTabNav,
        ))
      ],
    );
  }
}
