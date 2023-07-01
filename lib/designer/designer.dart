import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/widget_component.dart';
import 'package:xui_flutter/widget/cw_breadcrumb.dart';
import '../core/widget/cw_factory.dart';
import '../deprecated/core_array.dart';
import '../test_loader.dart';
import '../widget/cw_switch.dart';
import '../widget/cw_container.dart';
import '../widget/cw_dialog.dart';
import '../widget/cw_image.dart';
import '../core/widget/cw_core_selector.dart';
import '../widget/cw_tab.dart';
import '../widget/cw_text.dart';
import '../widget/cw_textfield.dart';
import 'widget_properties.dart';
import 'selector_manager.dart';
import 'package:flutter_json_viewer/flutter_json_viewer.dart';

// ignore: must_be_immutable
class CoreDesigner extends StatefulWidget {
  CoreDesigner({super.key});

  static GlobalKey imageKey = GlobalKey();
  static GlobalKey propKey = GlobalKey();

  late CWLoader loader;

  static late CoreDesigner coreDesigner;

  final ScrollController scrollComponentController = ScrollController(
    initialScrollOffset: 0.0,
    keepScrollOffset: true,
  );

  final ScrollController scrollPropertiesController = ScrollController(
    initialScrollOffset: 0.0,
    keepScrollOffset: true,
  );

  late TabController controllerTabRight;

  Widget getRoot() {
    coreDesigner = this;
    LoaderCtx ctx = LoaderCtx();
    ctx.collection = CWCollection().collection;
    ctx.mode = ModeRendering.design;
    loader = CWLoaderTest(ctx);
    return loader.getWidget();
  }

  @override
  State<CoreDesigner> createState() => _CoreDesignerState();
}

class RouteTest extends Route {
  RouteTest({super.settings});
}

class _CoreDesignerState extends State<CoreDesigner>
    with SingleTickerProviderStateMixin {
  final PageStorageBucket _bucket = PageStorageBucket();

  List<Widget> get getListComponent {
    return [
      CardComponents("Layout", [
        CmpDesc('Label', Icons.format_quote, CWText),
        CmpDesc('Column', Icons.table_rows_rounded, CWColumn),
        CmpDesc('Row', Icons.view_week, CWRow),
        CmpDesc('Tab', Icons.tab, CWTab)
      ]), // "Column", "Row", "Tab"
      // CardComponents("Filter", const [
      //   "Form",
      //   "Selector",
      // ]),
      // CardComponents(
      //     "Data", const ["Form", "List", "Tree" "List/Form", "Tree/Form"]),
      // CardComponents("Aggregat", const ["Sum", "Moy", "Count", "Chart"]),
      CardComponents("Input", [
        CmpDesc('Text', Icons.text_fields, CWTextfield),
        CmpDesc('Switch', Icons.toggle_on, CWSwitch),
      ]),
    ];
  }

  @override
  void initState() {
    super.initState();
    widget.controllerTabRight = TabController(
        vsync: this,
        length: 2,
        animationDuration: const Duration(milliseconds: 200));
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
            title: Container(
                // color: Colors.blue.withOpacity(0.3),
                child: // Text('ElisView'),
                    BreadCrumbNavigator(currentRouteStack)),
          ),
          body: PageStorage(bucket: _bucket, child: nav),
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
    return const Row();
  }

  Widget getDebugPan() {
    return Container(
        color: Colors.white, child: JsonViewer(widget.loader.cwFactory.value));
  }

  Column getTestPan() {
    return Column(children: [
      const DialogExample(key: PageStorageKey<String>('pageMain')),
      CwImage(key: CoreDesigner.imageKey),
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

  Widget getDesignerBody() {
    return Stack(key: SelectorActionWidget.designerKey, children: [
      Center(
          child: SizedBox(
              height: 896,
              width: 414,
              child: Material(
                  key: SelectorActionWidget.rootKey,
                  elevation: 5,
                  child: widget.getRoot()))),
      SelectorActionWidget(key: SelectorActionWidget.actionPanKey)
    ]);
  }

  Widget getDesignerText() {
    return Container(
        transform: Matrix4.translationValues(0, -10, 0),
        height: 45,
        decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(width: 1.0, color: Colors.black))),
        child: const TextField(
          style: TextStyle(color: Colors.red, fontSize: 15),
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: 'b',
            //     contentPadding: EdgeInsets.symmetric(horizontal: 0)
          ),
          autofocus: false,
        ));
  }

  Widget getDesignPan() {
    return Row(children: [
      Expanded(child: getDesignerBody()),
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
        child: DesignerProp(key: CoreDesigner.propKey)));

    listTabCont.add(SingleChildScrollView(
        key: const PageStorageKey<String>('pageWidget'),
        controller: widget.scrollComponentController,
        scrollDirection: Axis.vertical,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: getListComponent))); // const Steps());

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

class Component {
  Component(this.name, this.icon);
  String name;
  Icon icon;
}

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
