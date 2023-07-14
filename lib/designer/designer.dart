import 'package:event_listener/event_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/widget_component.dart';
import 'package:xui_flutter/widget/cw_breadcrumb.dart';

import '../deprecated/core_array.dart';
import '../widget/cw_dialog.dart';
import '../widget/cw_image.dart';
import 'cw_factory.dart';
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

  static CoreDesigner of() {
    return _coreDesigner;
  }

  static DesignerView ofView() {
    return _coreDesigner.view;
  }

  static CWLoader ofLoader() {
    return _coreDesigner.view.loader;
  }

  static WidgetFactoryEventHandler ofFactory() {
    return _coreDesigner.view.factory;
  }

  static late CoreDesigner _coreDesigner;
  final DesignerView view = DesignerView();

  final GlobalKey imageKey = GlobalKey(debugLabel: "CoreDesigner.imageKey");
  final GlobalKey propKey = GlobalKey(debugLabel: "CoreDesigner.propKey");
  final GlobalKey designerKey =
      GlobalKey(debugLabel: "CoreDesignerdesignerKey");

  final _eventListener = EventListener();

  final ScrollController scrollComponentController = ScrollController(
    initialScrollOffset: 0.0,
    keepScrollOffset: true,
  );

  final ScrollController scrollPropertiesController = ScrollController(
    initialScrollOffset: 0.0,
    keepScrollOffset: true,
  );

  late TabController controllerTabRight;

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
    widget.controllerTabRight = TabController(
        vsync: this,
        length: 2,
        animationDuration: const Duration(milliseconds: 200));

    Future.delayed(const Duration(milliseconds: 500), () {
      CWWidget wid = CoreDesigner.of().view.factory.mapWidgetByXid['root']!;
      CoreDesigner.emit(CDDesignEvent.select, wid.ctx);
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.controllerTabRight.dispose();
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
                  const Text('ElisView v0.1')
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
    return Row(
      children: [
        const SizedBox(
          width: 200,
          child: DesignerListModel(),
        ),
        Expanded(
            child: Container(
            color: Colors.black26,
          child: Stack(
            children: [
              Positioned(
                  left: 20,
                  top: 20,
                  width: 200,
                  // height: 500,
                  child: Container(
                      decoration:
                          BoxDecoration(border: Border.all(color: Colors.grey)),
                      width: 100,
                      child: DesignerModel()))
            ],
          ),
        )),
        Container(
          width: 300,
          child: Column(children: AttributDesc.getListAttr),
        )
      ],
    );
  }

  Widget getDebugPan() {
    return Container(
      color: Colors.white,
      // child: JsonViewer(CoreDesigner.ofLoader().cwFactory.value)
    );
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

  // Widget getDesignerText2() {
  //   return Container(
  //       transform: Matrix4.translationValues(0, -10, 0),
  //       height: 45,
  //       decoration: const BoxDecoration(
  //           border:
  //               Border(bottom: BorderSide(width: 1.0, color: Colors.black))),
  //       child: const TextField(
  //         style: TextStyle(color: Colors.red, fontSize: 15),
  //         decoration: InputDecoration(
  //           border: InputBorder.none,
  //           labelText: 'b',
  //           //     contentPadding: EdgeInsets.symmetric(horizontal: 0)
  //         ),
  //         autofocus: false,
  //       ));
  // }

  Widget getDesignPan() {
    return Row(children: [
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

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
      return Column(children: <Widget>[
        getTabActionLayout(listTab),
        Container(
            padding: const EdgeInsets.all(0.0),
            decoration: BoxDecoration(
                border:
                    Border.all(color: Theme.of(context).secondaryHeaderColor)),
            height: viewportConstraints.maxHeight - 40 - 2,
            child: TabBarView(
                controller: widget.controllerTabRight, children: listTabCont))
      ]);
    });
  }

  Widget getTabActionLayout(List<Widget> listTab) {
    return SizedBox(
      height: 40,
      child: ColoredBox(
          color: Colors.transparent,
          child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                  color: Theme.of(context).highlightColor,
                  child: TabBar(
                    controller: widget.controllerTabRight,
                    indicator: const UnderlineTabIndicator(
                        borderSide:
                            BorderSide(width: 4, color: Colors.deepOrange),
                        insets: EdgeInsets.only(left: 0, right: 0, bottom: 0)),
                    isScrollable: true,
                    //labelPadding: EdgeInsets.only(left: 0, right: 0),
                    tabs: listTab,
                  )))),
    );
  }
}

// class Component {
//   Component(this.name, this.icon);
//   String name;
//   Icon icon;
// }

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
