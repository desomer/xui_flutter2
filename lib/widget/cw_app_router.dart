import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';
import 'package:xui_flutter/designer/action_manager.dart';

import '../core/widget/cw_core_slot.dart';
import 'cw_action.dart';
import 'cw_app.dart';

class ActionLink {
  ActionLink(this.id, this.name, this.route, this.ctxApp);

  String id;
  String name;
  String route;
  bool? selected;
  CWWidgetCtx ctxApp;
}

class ScaffoldResponsiveDrawer extends StatelessWidget {
  ScaffoldResponsiveDrawer(
      {super.key, required this.appBar, required this.body});

  final AppBar appBar;
  final Widget body;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 800) {
        return Scaffold(
          key: scaffoldKey,
          drawer: getDrawer(),
          appBar: appBar,
          body: body,
        );
      } else {
        return Scaffold(
          key: scaffoldKey,
          appBar: appBar,
          body: Row(
            children: [getDrawer(), Expanded(child: body)],
          ),
        );
      }
    });
  }

  Drawer getDrawer() {
    return Drawer(
      width: 300,
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            // decoration: BoxDecoration(
            //   color: Colors.blue,
            // ),
            child: Text('Drawer Header'),
          ),
          ListTile(
              title: const Text('Home'),
              //selected: _selectedIndex == 0,
              onTap: () {
                // Update the state of the app
                //_onItemTapped(0);
                // Then close the drawer
                if (scaffoldKey.currentState!.isDrawerOpen) {
                  scaffoldKey.currentState!.closeDrawer();
                }
              }),
          ListTile(
            title: const Text('Business'),
            //selected: _selectedIndex == 1,
            onTap: () {
              // Update the state of the app
              //_onItemTapped(1);
              // Then close the drawer
              if (scaffoldKey.currentState!.isDrawerOpen) {
                scaffoldKey.currentState!.closeDrawer();
              }
            },
          ),
          ListTile(
            title: const Text('School'),
            //selected: _selectedIndex == 2,
            onTap: () {
              // Update the state of the app
              //_onItemTapped(2);
              // Then close the drawer
              if (scaffoldKey.currentState!.isDrawerOpen) {
                scaffoldKey.currentState!.closeDrawer();
              }
            },
          ),
        ],
      ),
    );
  }
}

/// ***********************************************************************
///  gestion par Scaffold With NavigationBar  ou  NavigationRail
///  gestion de l'animation  grace à AnimatedBranchContainer
///
class ScaffoldWithNestedNavigation extends StatelessWidget {
  const ScaffoldWithNestedNavigation(
      {super.key,
      required this.navigationShell,
      required this.children,
      required this.listAction});

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;
  final List<ActionLink> listAction;

  void _goBranch(int index) {
    // navigationShell.goBranch(
    //   index,
    //   // A common pattern when using bottom navigation bars is to support
    //   // navigating to the initial location when tapping the item that is
    //   // already active. This example demonstrates how to support this behavior,
    //   // using the initialLocation parameter of goBranch.
    //   initialLocation: index == navigationShell.currentIndex,
    // );
    //CWApplication.of().goRoute(listAction[index].route);
    for (var element in listAction) {
      element.selected = false;
    }
    listAction[index].selected = true;
    //CWApplication.of().goRoute(CWApplication.of().listPages[index].route);
    var id = 'rootNav$index';
    CWWidget? w = listAction[index].ctxApp.findWidgetInSlot(id);
    if (w is CWActionManager) {
      (w as CWActionManager).doAction(null, w!, w.ctx.designEntity?.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentPage = navigationShell.currentIndex;
    int currentAction = 0;
    for (var i = 0; i < listAction.length; i++) {
      if (listAction[i].selected == true) {
        currentAction = i;
        break;
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      if (listAction.length < 2) {
        return AnimatedBranchContainer(
          currentIndex: currentPage,
          children: children,
        );
      }

      if (constraints.maxWidth < 450) {
        return ScaffoldWithNavigationBar(
          listAction: listAction,
          body: AnimatedBranchContainer(
            currentIndex: currentPage,
            children: children,
          ),
          selectedActionIndex: currentAction,
          onDestinationSelected: _goBranch,
        );
      } else {
        return ScaffoldWithNavigationRail(
          listAction: listAction,
          body: AnimatedBranchContainer(
            currentIndex: currentPage,
            children: children,
          ),
          selectedActionIndex: currentAction,
          onDestinationSelected: _goBranch,
        );
      }
    });
  }
}

/////////////////////////////////////////////////////////////////////////
class ScaffoldWithNavigationBar extends StatelessWidget with CWSlotManager {
  const ScaffoldWithNavigationBar(
      {super.key,
      required this.body,
      required this.selectedActionIndex,
      required this.onDestinationSelected,
      required this.listAction});
  final Widget body;
  final int selectedActionIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ActionLink> listAction;

  BottomNavigationBar getBottomNavigation() {
    List<BottomNavigationBarItem> listBtn = [];
    int i = 0;
    for (var element in listAction) {
      var slot = CWSlot(
        type: 'navigation',
        key: GlobalKey(debugLabel: 'slot ${element.ctxApp.xid}Nav$i'),
        ctx: createChildCtx(element.ctxApp, 'Nav', i),
        slotAction: SlotNavAction('Nav', iDnbBtnBottomNavBar),
      );

      listBtn.add(BottomNavigationBarItem(label: '', icon: slot));
      i++;
    }

    return BottomNavigationBar(
        currentIndex: selectedActionIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: listBtn,
        type: BottomNavigationBarType.fixed,
        onTap: (int indexOfItem) {
          onDestinationSelected(indexOfItem);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: body,
        bottomNavigationBar: MediaQuery(
          data: MediaQuery.of(context).removePadding(removeBottom: true),
          child: getBottomNavigation(),
        ));
  }
}

class ScaffoldWithNavigationRail extends StatelessWidget with CWSlotManager {
  const ScaffoldWithNavigationRail(
      {super.key,
      required this.body,
      required this.selectedActionIndex,
      required this.onDestinationSelected,
      required this.listAction});
  final Widget body;
  final int selectedActionIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ActionLink> listAction;

  @override
  Widget build(BuildContext context) {
    var actions = <NavigationRailDestination>[];

    int i = 0;
    for (var element in listAction) {
      var slot = CWSlot(
        type: 'navigation',
        key: GlobalKey(debugLabel: 'slot ${element.ctxApp.xid}Nav$i'),
        ctx: createChildCtx(element.ctxApp, 'Nav', i),
        slotAction: SlotNavAction('Nav', iDnbBtnBottomNavBar),
      );

      actions.add(NavigationRailDestination(
          //label: Text(element.name), icon: Icon(element.icon)
          label: Container(),
          icon: slot));
      i++;
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
              selectedIndex: selectedActionIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.none,
              destinations: actions),
          const VerticalDivider(thickness: 1, width: 1),
          // This is the main content.
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////
class AnimatedBranchContainer extends StatelessWidget {
  /// Creates a AnimatedBranchContainer
  const AnimatedBranchContainer(
      {super.key, required this.currentIndex, required this.children});

  /// The index (in [children]) of the branch Navigator to display.
  final int currentIndex;

  /// The children (branch Navigators) to display in this container.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: children.mapIndexed(
      (int index, Widget navigator) {
        return AnimatedScale(
          scale: index == currentIndex ? 1 : 0.7,
          duration: const Duration(milliseconds: 300),
          child: AnimatedOpacity(
            opacity: index == currentIndex ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: _branchNavigatorWrapper(index, navigator),
          ),
        );
      },
    ).toList());
  }

  Widget _branchNavigatorWrapper(int index, Widget navigator) => IgnorePointer(
        ignoring: index != currentIndex,
        child: TickerMode(
          enabled: index == currentIndex,
          child: navigator,
        ),
      );
}

class SlotNavAction extends SlotAction {
  SlotNavAction(this.tag, this.varTag, {this.ctxConstraint});

  final String tag;
  final String varTag;
  final CWWidgetCtx? ctxConstraint;

  @override
  bool canDelete() {
    return true;
  }

  @override
  bool doDelete(CWWidgetCtx ctx) {
    return DesignActionManager().doDeleteSlot(ctx,
        DesignActionConfig(tag, varTag, false, ctxConstraint: ctxConstraint));
  }

  @override
  bool addBottom(CWWidgetCtx ctx) {
    return false;
  }

  @override
  bool canAddBottom() {
    return false;
  }

  @override
  bool addTop(CWWidgetCtx ctx) {
    return false;
  }

  @override
  bool canAddTop() {
    return false;
  }

  @override
  bool canMoveBottom() {
    return false;
  }

  @override
  bool moveBottom(CWWidgetCtx ctx) {
    return false;
  }

  @override
  bool canMoveTop() {
    return false;
  }

  @override
  bool moveTop(CWWidgetCtx ctx) {
    return false;
  }

  @override
  bool addLeft(CWWidgetCtx ctx) {
    return DesignActionManager().addBeforeOrAfter(ctx,
        DesignActionConfig(tag, varTag, true, ctxConstraint: ctxConstraint));
  }

  @override
  bool addRight(CWWidgetCtx ctx) {
    return DesignActionManager().addBeforeOrAfter(ctx,
        DesignActionConfig(tag, varTag, false, ctxConstraint: ctxConstraint));
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
    return true;
  }

  @override
  bool canMoveRight() {
    return true;
  }

  @override
  bool moveLeft(CWWidgetCtx ctx) {
    return DesignActionManager().moveBeforeOrAfter(ctx,
        DesignActionConfig(tag, varTag, true, ctxConstraint: ctxConstraint));
  }

  @override
  bool moveRight(CWWidgetCtx ctx) {
    return DesignActionManager().moveBeforeOrAfter(ctx,
        DesignActionConfig(tag, varTag, false, ctxConstraint: ctxConstraint));
  }
}
