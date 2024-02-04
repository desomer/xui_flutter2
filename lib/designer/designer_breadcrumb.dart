import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/core/widget/cw_factory.dart';

import '../core/widget/cw_core_loader.dart';
import 'designer_selector_properties.dart';
import 'help/widget_over_cmp.dart';
import 'selector_manager.dart';

class BreadCrumbNavigator extends StatefulWidget {
  const BreadCrumbNavigator({super.key});

  @override
  State<StatefulWidget> createState() {
    return _BreadCrumbNavigatorState();
  }
}

class _BreadCrumbNavigatorState extends State {

  @override
  Widget build(BuildContext context) {
    List<Route> currentRouteStack = [];

    List<DesignCtx> listPath = CoreDesignerSelector.of().propBuilder.listPath;
    for (var element in listPath) {
      currentRouteStack.add(RouteCmp(
          settings:
              RouteSettings(name: CWWidgetCollectionBuilder.getWidgetName(element.designEntity!.type))));
    }

    return RowSuper(
      mainAxisSize: MainAxisSize.min,
      innerDistance: -16,
      children: List<Widget>.from(currentRouteStack
          .asMap()
          .map(
            (index, value) => MapEntry(
                index,
                WidgetOverCmp(path:listPath[index].pathWidget, mode: index == 0?'1clip':'clip',
                    child: GestureDetector(
                        onTap: () {
                          OnWidgetSelect(listPath[index]).execute(null, null);
                        },
                        child: _BreadButton(
                            index == 0
                                ? 'Page'
                                : currentRouteStack[index].settings.name!,
                            index == 0)))),
          )
          .values),
    );
  }
}



class RouteCmp extends Route {
  RouteCmp({super.settings});
}

class _BreadButton extends StatelessWidget {
  final String text;
  final bool isFirstButton;

  const _BreadButton(this.text, this.isFirstButton);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: TriangleClipper(!isFirstButton),
      child: Container(
        color: Theme.of(context).highlightColor,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
              start: isFirstButton ? 8 : 30, end: 28, top: 8, bottom: 8),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  final bool twoSideClip;

  TriangleClipper(this.twoSideClip);

  @override
  Path getClip(Size size) {
    final Path path = Path();
    if (twoSideClip) {
      path.moveTo(0, 0.0);
      path.lineTo(20.0, size.height / 2);
      path.lineTo(0, size.height);
    } else {
      path.lineTo(0, size.height);
    }
    path.lineTo(size.width - 20, size.height);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - 20, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
