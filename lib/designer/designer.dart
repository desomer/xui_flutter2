import 'dart:async';

import 'package:event_listener/event_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/designer/widget/widget_debug.dart';
import 'package:xui_flutter/designer/widget/widget_drag_file.dart';
import 'package:xui_flutter/designer/widget/widget_tab.dart';
import 'package:xui_flutter/widget/cw_breadcrumb.dart';

import '../core/store/driver.dart';
import '../core/widget/cw_core_bind.dart';
import '../db_icon_icons.dart';
import 'cw_factory.dart';
import 'designer_model_attribut.dart';
import 'designer_model_data.dart';
import 'designer_model.dart';
import 'designer_selector_query.dart';
import 'designer_editor.dart';
import 'help/widget_hidden_box.dart';
import 'widget/plateform/widget_image.dart';
import 'widget/widget_preview.dart';
import 'designer_selector_attribut.dart';
import 'widget_filter_builder.dart';

enum CDDesignEvent { select, reselect, preview, save, clear }

final log = Logger('CoreDesigner');

// ignore: must_be_immutable
class CoreDesigner extends StatefulWidget {
  CoreDesigner({super.key}) {
    _coreDesigner = this;

    log.fine('init event listener');
    CoreDesigner.on(CDDesignEvent.save, (arg) async {
      log.fine('save action');
      StoreDriver? storage = await StoreDriver.getDefautDriver('main');
      storage?.setData('#pages', CoreDesigner.ofLoader().cwFactory.value);
    });
    CoreDesigner.on(CDDesignEvent.clear, (arg) async {
      log.fine('clear action');
      StoreDriver? storage = await StoreDriver.getDefautDriver('main');
      storage?.deleteData('#pages', []);
      CoreDesigner.ofView().clearAll();
      // ignore: invalid_use_of_protected_member
      CoreDesigner.of().designerKey.currentState?.setState(() {});
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

  final GlobalKey imageKey = GlobalKey(debugLabel: 'CoreDesigner.imageKey');
  final GlobalKey rootKey = GlobalKey(debugLabel: 'rootKey');
  final GlobalKey designerKey =
      GlobalKey(debugLabel: 'CoreDesignerdesignerKey');
  final GlobalKey propKey = GlobalKey(debugLabel: 'CoreDesigner.propKey');

  //final GlobalKey dataKey = GlobalKey(debugLabel: 'CoreDesigner.dataKey');
  final GlobalKey dataFilterKey =
      GlobalKey(debugLabel: 'CoreDesigner.dataFilterKey');

  final GlobalKey providerKey =
      GlobalKey(debugLabel: 'CoreDesigner.designerProviderKey');

  final _eventListener = EventListener();
  final editor = DesignerEditor();
  late DesignerView designView = DesignerView(key: designerKey);

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
      widget.editor,
      getDataPan(),
      getQueryPan(),
      const WidgetDebug(),
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
        key: CoreDesigner.of().rootKey,
        debugShowCheckedModeBanner: false,
        title: 'ElisView',
        theme: ThemeData(
          tabBarTheme: const TabBarTheme(labelColor: Colors.white),
          secondaryHeaderColor: Colors.grey.shade800,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: Brightness.dark,
          ),
        ),
        home: Scaffold(
          appBar: AppBar(
            title: Row(children: [
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
              const Text('ElisView v0.4.3'),
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
              widget.editor.controllerTabRight.index = 1;
            },
          ),
          bottomNavigationBar: BottomAppBar(
              height: 40,
              shape: const CircularNotchedRectangle(),
              notchMargin: 8.0,
              padding: EdgeInsets.zero,
              child: Row(
                // mainAxisSize: MainAxisSize.max,
                //  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          onPressed: () {
                            CoreDesigner.emit(CDDesignEvent.clear, null);
                          },
                        )),
                  ]),
                  const Spacer(),
                  const Text('Desomer G.  14/11/23'),
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
                  // decoration: BoxDecoration(
                  //   color: Colors.blue,
                  // ),
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

  Widget getDataPan() {
    WidgetTab tabModelDesc = WidgetTab(
      heightTab: 60,
      listTab: const [
        Tab(text: 'Model', icon: Icon(Icons.data_object)),
        Tab(text: 'Data', icon: Icon(Icons.table_chart)),
        Tab(text: 'Import', icon: Icon(Icons.import_export))
      ],
      listTabCont: [
        Column(children: [
          Expanded(
              child: Row(
            children: [
              Expanded(
                  child: Column(
                children: [
                  const Expanded(child: DesignerModel()), // les attributs
                  WidgetHiddenBox(child: const DesignerModelAttribut())
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
                mode: FilterBuilderMode.data,
                key: widget.dataFilterKey,
                bindWidget: CWApplication.of().bindFilter),
            Expanded(
                child: DesignerData(
                    /*key: widget.dataKey,*/ bindWidget:
                        CWApplication.of().bindData))
          ],
        ),
        Container()
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

  Widget getQueryPan() {
    CWWidgetCtx ctx = CWWidgetCtx('', CWApplication.of().loaderModel, '');
    ctx.designEntity = CWApplication.of()
        .loaderModel
        .collectionWidget
        .createEntityByJson('CWArray', {'providerName': 'DataModelProvider'});

    CWBindWidget bindFilter = CWBindWidget(ModeBindWidget.selected);

    return Row(
      children: [
        SizedBox(
            width: 300,
            child: DesignerQuery(
                mode: FilterBuilderMode.query,
                ctx: ctx,
                listBindWidget: [bindFilter, CWApplication.of().bindDataQuery])),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
            child: Column(
          children: [
            Container(
              height: 30,
              width: double.maxFinite,
              padding: const EdgeInsets.all(6),
              color: Theme.of(context).highlightColor,
              child: const Row(children: [
                Icon(Icons.filter_alt_outlined),
                SizedBox(width: 10),
                Text('Filter')
              ]),
            ),
            WidgetFilterbuilder(
                mode: FilterBuilderMode.query,
                key: widget.dataFilterKey,
                bindWidget: bindFilter),
            const Divider(height: 1),
            Expanded(
                child: Row(children: [
              SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      Container(
                        height: 30,
                        width: double.maxFinite,
                        padding: const EdgeInsets.all(6),
                        color: Theme.of(context).highlightColor,
                        child: const Row(children: [
                          Icon(Icons.manage_search_outlined),
                          SizedBox(width: 10),
                          Text('Parameters')
                        ]),
                      )
                    ],
                  )),
              const VerticalDivider(width: 1),
              Expanded(
                  child: DesignerData(
                      bindWidget: CWApplication.of().bindDataQuery))
            ]))
          ],
        )),
      ],
    );
  }

  Widget getTestPan() {
    Widget img =
        Plateform().getImage('https://googleflutter.com/sample_image.jpg');

    return SingleChildScrollView(
        child: Column(children: [
      img,
      const WidgetDragTarget(),
      // const DialogExample(key: PageStorageKey<String>('pageMain')),
      //CwImage(key: CoreDesigner.of().imageKey),
      // MaterialColorPicker(
      //     onColorChange: (Color color) {
      //       debugPrint(color.toString());
      //     },
      //     onMainColorChange: (ColorSwatch<dynamic>? color) {
      //       debugPrint(color!.value.toString());
      //     },
      //     selectedColor: Colors.red)
    ]));
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
          //selectedIconTheme: const IconThemeData(color: Colors.deepOrange),
          // unselectedIconTheme: const IconThemeData(color: Colors.blueGrey),
          // selectedLabelTextStyle: const TextStyle(color: Colors.green),
          // unselectedLabelTextStyle: const TextStyle(color: Colors.blueGrey),
          selectedIndex: selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              selectedIndex = index;
              pageController.jumpToPage(index);

              if (index == 0) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  CoreDesigner.emit(CDDesignEvent.reselect, null);
                });
              }
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
              icon: Tooltip(message: 'Query', child: Icon(Icons.manage_search)),
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
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
            child: PageView(
          controller: pageController,
          children: widget.listTabNav,
        ))
      ],
    );
  }
}
