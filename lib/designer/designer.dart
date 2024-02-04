import 'dart:async';

import 'package:event_listener/event_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/designer/widget/widget_debug.dart';
import 'package:xui_flutter/designer/widget/widget_drag_file.dart';
import 'package:xui_flutter/designer/widget/widget_tab.dart';
import 'package:xui_flutter/designer/designer_breadcrumb.dart';

import '../core/data/core_data_query.dart';
import '../core/data/core_repository.dart';
import '../core/store/driver.dart';
import '../core/widget/cw_core_bind.dart';
import '../db_icon_icons.dart';
import '../core/widget/cw_factory.dart';
import 'designer_model_list.dart';
import 'designer_model_attribut.dart';
import 'designer_model_data.dart';
import 'designer_model.dart';
import 'designer_selector_query.dart';
import 'designer_page_editor.dart';
import 'help/widget_hidden_box.dart';
import 'help/widget_no_visible_on_resize.dart';
import 'selector_manager.dart';
import 'widget/plateform/widget_image.dart';
import 'widget/widget_preview.dart';
import 'designer_selector_attribut.dart';
import 'widget_filter_builder.dart';

enum CDDesignEvent {
  select,
  reselect,
  preview,
  savePage,
  clear,
  saveModel,
  over,
  displayProp
}

final log = Logger('CoreDesigner');

// ignore: must_be_immutable
class CoreDesigner extends StatefulWidget {
  CoreDesigner({super.key}) {
    _coreDesigner = this;

    log.fine('init event listener');

    CoreDesigner.on(CDDesignEvent.saveModel, (arg) async {
      var app = CWApplication.of();
      await CoreGlobalCache.saveCache(app.dataModelProvider);
      await CoreGlobalCache.saveCache(app.dataProvider);
    });

    CoreDesigner.on(CDDesignEvent.savePage, (arg) async {
      log.fine('save action');
      StoreDriver? storage = await StoreDriver.getDefautDriver('main');
      storage?.setData('#pages', CoreDesigner.ofLoader().cwFactory.value);
    });

    CoreDesigner.on(CDDesignEvent.clear, (arg) async {
      log.fine('clear action');
      StoreDriver? storage = await StoreDriver.getDefautDriver('main');
      storage?.deleteData('#pages', []);
      CoreDesigner.ofView().clearAll();
      CoreDesigner.ofView().reBuild(false);
      Future.delayed(const Duration(milliseconds: 100), () {
        CWWidget wid =
            CoreDesigner.of().designView.factory.mapWidgetByXid['root']!;
        CoreDesigner.emit(CDDesignEvent.select, wid.ctx);
      });
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

  final GlobalKey imageKey = GlobalKey(debugLabel: 'imageKey');
  final GlobalKey rootKey = GlobalKey(debugLabel: 'rootKey');
  final GlobalKey designerKey = GlobalKey(debugLabel: 'designerKey');
  final GlobalKey propKey = GlobalKey(debugLabel: 'CoreDesigner.propKey');
  final GlobalKey styleKey = GlobalKey(debugLabel: 'CoreDesigner.styleKey');

  final GlobalKey queryKey = GlobalKey(debugLabel: 'designerQueryKey');
  final GlobalKey providerKey = GlobalKey(debugLabel: 'designerProviderKey');

  final GlobalKey dataFilterKey = GlobalKey(debugLabel: 'dataFilterKey');
  final GlobalKey navCmpKey = GlobalKey(debugLabel: 'navCmpKey');
  final GlobalKey pagesKey = GlobalKey(debugLabel: 'pagesKey');

  final _eventListener = EventListener();
  final editor = DesignerEditor();
  late DesignerView designView = DesignerView(key: designerKey);

  int ctrlTime = 0;
  int altTime = 0;

  bool isAltPress() {
    return DateTime.now().millisecondsSinceEpoch - altTime < 200;
  }

  @override
  State<CoreDesigner> createState() => _CoreDesignerState();
}

class _CoreDesignerState extends State<CoreDesigner>
    with SingleTickerProviderStateMixin {
  //final PageStorageBucket _bucket = PageStorageBucket();

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

  DebouncerAction alt = DebouncerAction(milliseconds: 400);

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
        home: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              LogicalKeySet(LogicalKeyboardKey.control): () {
                print("ctrl");
                int n = DateTime.now().millisecondsSinceEpoch;
                if (n - widget.ctrlTime > 200) {
                  print("start ctl");
                }
                widget.ctrlTime = n;
                alt.doAfter(() {
                  print("end ctl");
                });
              },
              LogicalKeySet(LogicalKeyboardKey.alt): () {
                print("alt");
                int n = DateTime.now().millisecondsSinceEpoch;
                if (n - widget.altTime > 200) {
                  print("start alt");
                  CoreDesignerSelector.of()
                      .getSelectedWidgetContext()
                      ?.getCWWidget()
                      ?.repaint();
                }
                widget.altTime = n;
                alt.doAfter(() {
                  print("end alt");
                  widget.altTime = DateTime.now().millisecondsSinceEpoch - 800;
                  CoreDesignerSelector.of()
                      .getSelectedWidgetContext()
                      ?.getCWWidget()
                      ?.repaint();
                });
              },
            },
            child: Scaffold(
              appBar: AppBar(
                title: Row(children: [
                  BreadCrumbNavigator(key: widget.navCmpKey),
                  const Spacer(),
                  const WidgetPreview(),
                  InkWell(
                    child: const Icon(size: 25, Icons.save),
                    onTap: () {
                      CoreDesigner.emit(CDDesignEvent.savePage, null);
                    },
                  ),
                  const SizedBox(width: 20),
                  const Text('ElisView v0.4.4'),
                  const SizedBox(width: 5),
                  IconButton(
                    iconSize: 30,
                    icon: const Icon(Icons.apps),
                    onPressed: () {},
                  )
                ]),
              ),
              body: nav, // PageStorage(bucket: _bucket, child: nav),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.miniCenterDocked,
              floatingActionButton: FloatingActionButton(
                elevation: 4,
                backgroundColor: Colors.deepOrange.shade400,
                mini: true,
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  widget.editor.controllerTabLeft.index = 0;
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
                      const Text('Desomer G.  24/12/23'),
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
            )));
  }

  Widget getDataPan() {
    WidgetTab tabModelDesc = WidgetTab(
      onController: (TabController a) {
        a.addListener(() async {
          if (a.indexIsChanging) {
            log.fine('change data tab ${a.index}');
            var app = CWApplication.of();
            await CoreGlobalCache.saveCache(app.dataProvider);
            await CoreGlobalCache.saveCache(app.dataModelProvider);
            app.refreshData();

            if (a.index == 1) {
              // re creer le tableau de data en fonction des changements du model
              CWApplication.of().bindModel2Data.rebindNested();
            }
          }
        });
        widget.editor.controllerTabData = a;
      },
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
                  Expanded(
                      child: DesignerModel(
                          bindWidget: CWApplication.of()
                              .bindModel2Attr)), // les attributs
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
                bindWidget: CWApplication.of().bindModel2Filter),
            Expanded(
                child: DesignerData(
                    /*key: widget.dataKey,*/ bindWidget:
                        CWApplication.of().bindModel2Data))
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
        .createEntityByJson('CWArray', {iDProviderName: 'DataModelProvider'});

    CWBindWidget bindFilter =
        CWBindWidget('bindFilter', ModeBindWidget.selected);

    return Row(
      children: [
        SizedBox(
            width: 300,
            child: DesignerQuery(
                mode: FilterBuilderMode.query,
                ctx: ctx,
                listBindWidget: [
                  bindFilter,
                  CWApplication.of().bindFilter2Data
                ])),
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
                Text('Filter clauses')
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
                      bindWidget: CWApplication.of().bindFilter2Data))
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
  void initState() {
    super.initState();
    pageController.addListener(() {
      print('pageController ${pageController.page}');
      if (pageController.page == 0) {
        // raffraichi le nom des filtres & tables
        Future.delayed(const Duration(milliseconds: 100), () {
          CoreDesigner.of().queryKey.currentState?.setState(() {});
        });
      }
    });
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
