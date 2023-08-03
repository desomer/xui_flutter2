import 'package:event_listener/event_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/widget_component.dart';
import 'package:xui_flutter/designer/widget_debug.dart';
import 'package:xui_flutter/designer/widget_tab.dart';
import 'package:xui_flutter/widget/cw_breadcrumb.dart';

import '../deprecated/core_array.dart';
import '../widget/cw_dialog.dart';
import '../widget/cw_image.dart';
import 'cw_factory.dart';
import 'designer_data.dart';
import 'designer_model.dart';
import 'designer_view.dart';
import 'widget_model_attribut.dart';
import 'widget_properties.dart';

enum CDDesignEvent { select, reselect }

// ignore: must_be_immutable
class CoreDesigner extends StatefulWidget {
  CoreDesigner({super.key}) {
    _coreDesigner = this;
  }

  static on(CDDesignEvent event, Function(dynamic) fct) {
    of()._eventListener.on(event.toString(), fct);
  }

  static emit(CDDesignEvent event, dynamic payload) {
    of()._eventListener.emit(event.toString(), payload);
  }

  static removeListener(CDDesignEvent event, Function(dynamic) fct) {
    of()._eventListener.removeEventListener(event.toString(), (argument) {});
  }

  static CoreDesigner of() {
    return _coreDesigner;
  }

  static DesignerView ofView() {
    return _coreDesigner.view;
  }

  static CWWidgetLoader ofLoader() {
    return _coreDesigner.view.loader;
  }

  static WidgetFactoryEventHandler ofFactory() {
    return ofLoader().ctxLoader.factory;
  }

  static late CoreDesigner _coreDesigner;
  final DesignerView view = DesignerView();

  final GlobalKey imageKey = GlobalKey(debugLabel: "CoreDesigner.imageKey");
  final GlobalKey propKey = GlobalKey(debugLabel: "CoreDesigner.propKey");
  final GlobalKey designerKey =
      GlobalKey(debugLabel: "CoreDesignerdesignerKey");

  final GlobalKey dataKey = GlobalKey(debugLabel: "CoreDesigner.dataKey");

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

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 500), () {
      CWWidget wid = CoreDesigner.of().view.factory.mapWidgetByXid['root']!;
      CoreDesigner.emit(CDDesignEvent.select, wid.ctx);
    });
  }

  @override
  Widget build(BuildContext context) {
    final NavRail nav = NavRail();
    nav.tab = [getDesignPan(), getDataPan(), getDebugPan(), getTestPan()];

    List<Route> currentRouteStack = [];
    currentRouteStack
        .add(RouteTest(settings: const RouteSettings(name: "Root")));
    currentRouteStack.add(RouteTest(settings: const RouteSettings(name: "B")));

    return MaterialApp(
        key: CoreDesigner.of().designerKey,
        debugShowCheckedModeBanner: false,
        title: 'ElisView',
        theme: ThemeData(),
        // standard dark theme
        darkTheme: ThemeData.dark().copyWith(
            indicatorColor: Colors.amber,
            inputDecorationTheme: const InputDecorationTheme(
                labelStyle: TextStyle(color: Colors.white70))),
        themeMode: ThemeMode.system,
        home: Scaffold(
          appBar: AppBar(
            title: Row(
                // color: Colors.blue.withOpacity(0.3),
                children: [
                  BreadCrumbNavigator(currentRouteStack),
                  const Spacer(),
                  const Text('ElisView v0.2.1'),
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
                  const Text("Desomer G."),
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

    WidgetTab tabAttributDesc = WidgetTab(heightTab: 30, listTab: const [
      Tab(text: "Description"),
      Tab(text: "Constraints")
    ], listTabCont: [
      Center(
        child: Container(
          width: 100,
          height: 100,
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
        ),
      ),
      Container()
    ]);

    WidgetTab tab = WidgetTab(
      heightTab: 60,
      listTab: const [
        Tab(text: "Model", icon: Icon(Icons.data_object)),
        Tab(text: "Data", icon: Icon(Icons.table_chart))
      ],
      listTabCont: [
        Column(children: [
          Expanded(
              child: Row(
            children: [
              Expanded(
                  child: Column(
                children: [
                  Expanded(child: viewAttribute),
                  SizedBox(
                    height: 200,
                    child: tabAttributDesc,
                  )
                ],
              )), // ),
              SizedBox(
                width: 300,
                child: Column(children: AttributDesc.getListAttr),
              )
            ],
          )),
          //
        ]),
        DesignerData(key: widget.dataKey)
      ],
    );

    return Row(
      children: [
        const SizedBox(
          width: 200,
          child: DesignerListModel(),
        ),
        Expanded(child: tab)
      ],
    );
  }

  Widget getDebugPan() {
    return const WidgetDebug();
  }

  Column getTestPan() {
    return Column(children: [
      const DialogExample(key: PageStorageKey<String>('pageMain')),
      CwImage(key: CoreDesigner.of().imageKey),
      const PlutoGridExamplePage(),
      MaterialColorPicker(
          onColorChange: (Color color) {
            debugPrint(color.toString());
          },
          onMainColorChange: (ColorSwatch<dynamic>? color) {
            debugPrint(color!.value.toString());
          },
          selectedColor: Colors.red)
    ]);
  }

  Widget getDesignPan() {
    return Row(children: [
      const SizedBox(
        width: 300,
        child: WidgetTab(heightTab: 40, listTab: [
          Tab(icon: Icon(Icons.near_me)),
          Tab(icon: Icon(Icons.query_stats))
        ], listTabCont: [
          Text("navigation"),
          Text("Query")
        ]),
      ),
      Expanded(child: widget.view),
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

  late List<Widget> tab;

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
              pageController.animateToPage(index,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn);
            });
          },
          destinations: const <NavigationRailDestination>[
            NavigationRailDestination(
              icon: Tooltip(
                  message: 'Edit Pages', child: Icon(Icons.edit_document)),
              label: Text('Edit'),
            ),
            NavigationRailDestination(
              icon:
                  Tooltip(message: 'Data', child: Icon(Icons.storage_rounded)),
              label: Text('Store'),
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
          children: widget.tab,
        ))
      ],
    );
  }
}
