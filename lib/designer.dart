import 'package:flutter/material.dart';
import 'widget/cw_builder.dart';
import 'widget/cw_image.dart';
import 'widget/cw_selector.dart';

class CoreDesigner extends StatefulWidget {
  const CoreDesigner({super.key});

  static GlobalKey imageKey = GlobalKey();

  Widget getRoot() {
    return CWCollection().getWidget();
  }

  @override
  State<CoreDesigner> createState() => _CoreDesignerState();
}

class _CoreDesignerState extends State<CoreDesigner> {
  @override
  Widget build(BuildContext context) {
    final NavRail nav = NavRail();
    nav.tab = [getDesignerColumnDesign(), CwImage(key:CoreDesigner.imageKey)];

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Designer',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
        ),
        home: Scaffold(
            appBar: AppBar(
              title: const Text('Designer'),
            ),
            body: nav));
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

  Widget getEditor() {
    return Column(children: [
      getDesignerText(),
      getDesignerText(),
      getDesignerText(),
      getDesignerText(),
    ]);
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
    listTabCont.add(getEditor());
    listTabCont.add(Container());

    return DefaultTabController(
        length: 2,
        child: LayoutBuilder(builder:
            (BuildContext context, BoxConstraints viewportConstraints) {
          return Column(children: <Widget>[
            SizedBox(
              height: 30,
              child: ColoredBox(
                  color: Colors.transparent,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                          color: Colors.blueGrey,
                          child: TabBar(
                            indicator: const UnderlineTabIndicator(
                                borderSide: BorderSide(
                                    width: 4, color: Colors.deepOrange),
                                insets: EdgeInsets.only(
                                    left: 0, right: 0, bottom: 0)),
                            isScrollable: true,
                            //labelPadding: EdgeInsets.only(left: 0, right: 0),
                            tabs: listTab,
                          )))),
            ),
            Container(
                padding: const EdgeInsets.all(3.0),
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.blueAccent)),
                height: viewportConstraints.maxHeight - 32,
                child: TabBarView(children: listTabCont))
          ]);
        }));
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
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        NavigationRail(
          minWidth: 40,
          labelType: NavigationRailLabelType.none,
          // selectedIconTheme: const IconThemeData(color: Colors.green),
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
              icon: Icon(Icons.edit_document),
              label: Text('Edit'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.storage_rounded),
              label: Text('Store'),
            ),
            // NavigationRailDestination(
            //   icon: Icon(Icons.message),
            //   label: Text('Feedback'),
            // ),
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
