import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:xui_flutter/core/widget/cw_core_widget.dart';

import '../core/widget/cw_core_slot.dart';

// void main() {
//   runApp(CwRouter());
// }

class ActionLink {
  ActionLink(this.name, this.icon, this.ctx);
  String name;
  IconData icon;
  CWWidgetCtx ctx;
}

// // ignore: must_be_immutable
// class CwRouter extends StatefulWidget {
//   CwRouter({Key? key, required this.body}) : super(key: key);

//   var listRoute = <StatefulShellBranch>[];
//   var listAction = <ActionLink>[];
//   final Widget body;

//   @override
//   State<CwRouter> createState() => _CwRouterState();

//   // CustomTransitionPage buildPageWithDefaultTransition<T>({
//   //   required BuildContext context,
//   //   required GoRouterState state,
//   //   required Widget child,
//   // }) {
//   //   return CustomTransitionPage<T>(
//   //     key: state.pageKey,
//   //     child: child,
//   //     transitionDuration: const Duration(seconds: 2),
//   //     transitionsBuilder: (context, animation, secondaryAnimation, child) =>
//   //         FadeTransition(opacity: animation, child: child),
//   //   );
//   // }

//   // Page<dynamic> Function(BuildContext, GoRouterState) animPageBuilder<T>(
//   //         Function(GoRouterState) fct) =>
//   //     (BuildContext context, GoRouterState state) {
//   //       return buildPageWithDefaultTransition<T>(
//   //         context: context,
//   //         state: state,
//   //         child: fct(state),
//   //       );
//   //     };

//   // StatefulShellBranch getRouteBranch(path) {
//   //   return StatefulShellBranch(routes: <RouteBase>[
//   //     GoRoute(
//   //       // The screen to display as the root in the first tab of the
//   //       // bottom navigation bar.
//   //       path: '/a',
//   //       builder: (BuildContext context, GoRouterState state) =>
//   //           const Center(child: Text("ok")),
//   //     )
//   //   ]);
//   // }
// }

// class _CwRouterState extends State<CwRouter> {
//   StatefulShellBranch getSubRoute(String path, Function(GoRouterState) fct) {
//     return StatefulShellBranch(routes: <RouteBase>[
//       GoRoute(
//         path: path,
//         //pageBuilder : animPageBuilder(fct)
//         builder: (context, state) {
//           return fct(state);
//         },
//       )
//     ]);
//   }

//   @override
//   void initState() {
//     super.initState();

//     // Future.delayed(const Duration(seconds: 5), () {
//     //   setState(() {
//     //     //FocusScope.of(context).unfocus();
//     //     FocusScope.of(context).requestFocus(FocusNode());

//     //     var r3 = getSubRoute('/c', (state) {
//     //       return const Center(child: Text('test dyn'));
//     //     });

//     //     widget.listRoute.add(r3);
//     //     widget.listAction.add(ActionLink('super 3', Icons.add_link));
//     //   });
//     // });

//     // Future.delayed(const Duration(seconds: 10), () {
//     //   setState(() {
//     //     //FocusScope.of(context).unfocus();
//     //     FocusScope.of(context).requestFocus(FocusNode());

//     //     var r3 = getSubRoute('/d', (state) {
//     //       return Scaffold(
//     //           appBar: AppBar(title: const Text('AppBar 2')),
//     //           body: const Center(child: Text('super bar')));
//     //     });

//     //     widget.listRoute.add(r3);
//     //     widget.listAction.add(ActionLink('super 4', Icons.album));
//     //   });
//     // });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.listRoute.isEmpty) {
//       var r1 = getSubRoute('/', (state) {
//         return ScaffoldDrawer(
//             appBar: AppBar(elevation: 0, title: const Text('AppBar')),
//             body: ClipRRect(
//                 borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(20),
//                     topRight: Radius.circular(20)),
//                 child: Container(color: Colors.white, child: widget.body)));
//       });

//       var r2 = getSubRoute('/b', (state) {
//         return const Center(child: Text('test ok'));
//       });

//       widget.listRoute.add(r1);
//       widget.listRoute.add(r2);
//       widget.listAction.add(ActionLink('super 1', Icons.ac_unit));
//       widget.listAction.add(ActionLink('super 2', Icons.access_alarm));
//     }
//     //*******************************************************************/
//     final GlobalKey<NavigatorState> rootNavigatorKey =
//         GlobalKey<NavigatorState>(debugLabel: 'root');

//     final GoRouter router = GoRouter(
//         navigatorKey: rootNavigatorKey,
//         initialLocation: '/',
//         routes: <RouteBase>[
//           StatefulShellRoute(
//               builder: (BuildContext context, GoRouterState state,
//                   StatefulNavigationShell navigationShell) {
//                 // This nested StatefulShellRoute demonstrates the use of a
//                 // custom container for the branch Navigators. In this implementation,
//                 // no customization is done in the builder function (navigationShell
//                 // itself is simply used as the Widget for the route). Instead, the
//                 // navigatorContainerBuilder function below is provided to
//                 // customize the container for the branch Navigators.
//                 return navigationShell;
//               },
//               navigatorContainerBuilder: (BuildContext context,
//                   StatefulNavigationShell navigationShell,
//                   List<Widget> children) {
//                 // Returning a customized container for the branch
//                 // Navigators (i.e. the `List<Widget> children` argument).
//                 //
//                 // See ScaffoldWithNavBar for more details on how the children
//                 // are managed (using AnimatedBranchContainer).
//                 return ScaffoldWithNestedNavigation(
//                     //key: GlobalKey(),
//                     listAction: widget.listAction,
//                     navigationShell: navigationShell,
//                     children: children);
//               },
//               branches: widget.listRoute)
//         ]);

//     return MaterialApp.router(
//       title: 'Flutter Demo',
//       routerConfig: router,
//       theme: ThemeData().copyWith(scaffoldBackgroundColor: Colors.blue),
//       debugShowCheckedModeBanner: false,
//       builder: DevicePreview.appBuilder,
//       locale: DevicePreview.locale(context),
//     );
//   }
// }

class ScaffoldResponsiveDrawer extends StatelessWidget {
  ScaffoldResponsiveDrawer(
      {super.key, required this.appBar, required this.body});

  //int _selectedIndex = 0;

  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }

  final AppBar appBar;
  final Widget body;
  final scaffoldKey = GlobalKey<ScaffoldState>();

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
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
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
}

class ScaffoldWithNestedNavigation extends StatelessWidget {
  const ScaffoldWithNestedNavigation(
      {super.key,
      required this.navigationShell,
      required this.children,
      required this.listAction}); // ?? const ValueKey<String>('ScaffoldWithNestedNavigation')

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;
  final List<ActionLink> listAction;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // A common pattern when using bottom navigation bars is to support
      // navigating to the initial location when tapping the item that is
      // already active. This example demonstrates how to support this behavior,
      // using the initialLocation parameter of goBranch.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (listAction.length < 2) {
        return AnimatedBranchContainer(
          currentIndex: navigationShell.currentIndex,
          children: children,
        );
      }

      if (constraints.maxWidth < 450) {
        return ScaffoldWithNavigationBar(
          listAction: listAction,
          body: AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          ),
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
        );
      } else {
        return ScaffoldWithNavigationRail(
          listAction: listAction,
          body: AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          ),
          selectedIndex: navigationShell.currentIndex,
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
      required this.selectedIndex,
      required this.onDestinationSelected,
      required this.listAction});
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ActionLink> listAction;

  BottomNavigationBar getBottomNavigation() {
    List<BottomNavigationBarItem> listBtn = [];
    int i = 0;
    for (var element in listAction) {
      var slot = CWSlot(
        type: 'navigation',
        key: GlobalKey(debugLabel: 'slot ${element.ctx.xid}Btn$i'),
        ctx: createChildCtx(element.ctx, 'Btn', i),
        slotAction: SlotNavAction(),
      );

      listBtn.add(BottomNavigationBarItem(
          label: '', //element.name,
          icon: slot
          //Icon(element.icon),
          ));
      i++;
    }

    return BottomNavigationBar(
        currentIndex: selectedIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        //fixedColor: Colors.green,
        items: listBtn,
        type: BottomNavigationBarType.fixed,
        onTap: (int indexOfItem) {
          onDestinationSelected(indexOfItem);
        });
  }

  @override
  Widget build(BuildContext context) {
    // var actions = <NavigationDestination>[];

    // for (var element in listAction) {
    //   actions.add(
    //       NavigationDestination(label: element.name, icon: Icon(element.icon)));
    // }

    return Scaffold(
        body: body,
        bottomNavigationBar: MediaQuery(
          data: MediaQuery.of(context).removePadding(removeBottom: true),
          child: getBottomNavigation(),
          // child: NavigationBar(
          //   height: 200,
          //   // type: BottomNavigationBarType.fixed,
          //   selectedIndex: selectedIndex,
          //   destinations: actions,
          //   onDestinationSelected: onDestinationSelected,
          // ),
        ));
  }
}

class ScaffoldWithNavigationRail extends StatelessWidget with CWSlotManager {
  const ScaffoldWithNavigationRail(
      {super.key,
      required this.body,
      required this.selectedIndex,
      required this.onDestinationSelected,
      required this.listAction});
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ActionLink> listAction;

  @override
  Widget build(BuildContext context) {
    var actions = <NavigationRailDestination>[];

    int i = 0;
    for (var element in listAction) {
      var slot = CWSlot(
        type: 'navigation',
        key: GlobalKey(debugLabel: 'slot ${element.ctx.xid}Btn$i'),
        ctx: createChildCtx(element.ctx, 'Btn', i),
        slotAction: SlotNavAction(),
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
              selectedIndex: selectedIndex,
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
  @override
  bool canDelete() {
    return true;
  }

  @override
  bool doDelete(CWWidgetCtx ctx) {
    return true;
  }

  @override
  bool addBottom(CWWidgetCtx ctx) {
    return true;
  }

  @override
  bool canAddBottom() {
    return true;
  }

  @override
  bool addTop(CWWidgetCtx ctx) {
    return true;
  }

  @override
  bool canAddTop() {
    return true;
  }

  @override
  bool canMoveBottom() {
    return true;
  }

  @override
  bool moveBottom(CWWidgetCtx ctx) {
    return true;
  }

  @override
  bool canMoveTop() {
    return true;
  }

  @override
  bool moveTop(CWWidgetCtx ctx) {
    return true;
  }
}
