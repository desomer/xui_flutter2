import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:flutter/material.dart';

class BreadCrumbNavigator extends StatelessWidget {
  final List<Route> currentRouteStack;

  const BreadCrumbNavigator(this.currentRouteStack, {super.key});

  @override
  Widget build(BuildContext context) {
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
                      debugPrint('RowSuper $index');
                      // Navigator.popUntil(context,
                      //     (route) => route == currentRouteStack[index]);
                    },
                    child: _BreadButton(
                        index == 0
                            ? 'Root'
                            : currentRouteStack[index].settings.name!,
                        index == 0))),
          )
          .values),
    );
  }
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
    path.lineTo(size.width-20, size.height);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width-20, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
