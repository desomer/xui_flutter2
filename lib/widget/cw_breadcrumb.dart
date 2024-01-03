import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:flutter/material.dart';

import '../core/widget/cw_core_loader.dart';
import '../designer/designer_selector_properties.dart';
import '../designer/selector_manager.dart';

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
      currentRouteStack.add(RouteTest(
          settings:
              RouteSettings(name: element.designEntity?.type.substring(2))));
    }

    return RowSuper(
      mainAxisSize: MainAxisSize.min,
      innerDistance: -16,
      children: List<Widget>.from(currentRouteStack
          .asMap()
          .map(
            (index, value) => MapEntry(
                index,
                GestureDetector(
                    onTap: () {
                      OnWidgetSelect(listPath[index]).execute(null, null);
                      //debugPrint('RowSuper $index');
                      // Navigator.popUntil(context,
                      //     (route) => route == currentRouteStack[index]);
                    },
                    child: _BreadButton(
                        index == 0
                            ? 'Page'
                            : currentRouteStack[index].settings.name!,
                        index == 0))),
          )
          .values),
    );
  }
}

class RouteTest extends Route {
  RouteTest({super.settings});
}

class _BreadButton extends StatelessWidget {
  final String text;
  final bool isFirstButton;

  const _BreadButton(this.text, this.isFirstButton);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TriangleClipper(!isFirstButton),
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

class _TriangleClipper extends CustomClipper<Path> {
  final bool twoSideClip;

  _TriangleClipper(this.twoSideClip);

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
