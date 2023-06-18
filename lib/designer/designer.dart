import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_core_loader.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import '../core/data/core_data.dart';
import '../core/widget/cw_factory.dart';
import '../widget/cw_dialog.dart';
import '../deprecated/cw_expand_panel.dart';
import '../widget/cw_image.dart';
import '../core/widget/cw_core_selector.dart';
import 'widget_properties.dart';
import 'widget_selector.dart';

// ignore: must_be_immutable
class CoreDesigner extends StatefulWidget {
  CoreDesigner({super.key});

  static GlobalKey imageKey = GlobalKey();
  static GlobalKey propKey = GlobalKey();

  final cwCollect = CWCollection();
  late CoreDataEntity aFrame;
  late CWLoader loader;

  final ScrollController scrollController = ScrollController(
    initialScrollOffset: 0.0,
    keepScrollOffset: true,
  );

  Widget getRoot() {
    DesignCtx ctx = DesignCtx();
    ctx.collection = cwCollect.collection;
    ctx.mode = ModeRendering.design;
    loader = CWLoaderTest(ctx);
    aFrame = loader.getWidgetEntity();
    return loader.getWidget(aFrame);
  }

  @override
  State<CoreDesigner> createState() => _CoreDesignerState();
}

class _CoreDesignerState extends State<CoreDesigner>
    with SingleTickerProviderStateMixin {
  final PageStorageBucket _bucket = PageStorageBucket();

  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
        vsync: this,
        length: 2,
        animationDuration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final NavRail nav = NavRail();
    nav.tab = [
      getDesignerColumnDesign(),
      Column(children: [
        const DialogExample(key: PageStorageKey<String>('pageMain')),
        CwImage(key: CoreDesigner.imageKey)
      ])
    ];

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
              title: const Text('ElisView'),
            ),
            body: PageStorage(bucket: _bucket, child: nav)));
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

  Widget getDesignerColumnDesign() {
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
      height: 30,
      icon: Icon(Icons.edit_note),
    ));

    listTab.add(const Tab(
      // height: 30,
      icon: Icon(Icons.access_time),
    ));

    final List<Widget> listTabCont = <Widget>[];
    listTabCont.add(Container(
        key: const PageStorageKey<String>('pageProp'),
        child: DesignerProp(key: CoreDesigner.propKey)));
    listTabCont.add(SingleChildScrollView(
        key: const PageStorageKey<String>('pageHisto'),
        controller: widget.scrollController,
        scrollDirection: Axis.vertical,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card3(),
          Card3(),
          Card3(),
          Card3(),
          Card3(),
          Card3(),
          Card3(),
          Card3(),
          Card3(),
          Card3()
        ]))); // const Steps());

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
      return Column(children: <Widget>[
        SizedBox(
          height: 40,
          child: ColoredBox(
              color: Colors.transparent,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                      color: Theme.of(context).highlightColor,
                      child: TabBar(
                        controller: _controller,
                        indicator: const UnderlineTabIndicator(
                            borderSide:
                                BorderSide(width: 4, color: Colors.deepOrange),
                            insets:
                                EdgeInsets.only(left: 0, right: 0, bottom: 0)),
                        isScrollable: true,
                        //labelPadding: EdgeInsets.only(left: 0, right: 0),
                        tabs: listTab,
                      )))),
        ),
        Container(
            padding: const EdgeInsets.all(0.0),
            decoration: BoxDecoration(
                border:
                    Border.all(color: Theme.of(context).secondaryHeaderColor)),
            height: viewportConstraints.maxHeight - 40 - 2,
            child: TabBarView(controller: _controller, children: listTabCont))
      ]);
    });
  }
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
