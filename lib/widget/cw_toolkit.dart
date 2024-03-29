import 'package:flutter/material.dart';

class CwToolkit {
  static Offset? getPosition(GlobalKey key, GlobalKey origin) {
    // ignore: cast_nullable_to_non_nullable
    final RenderObject? box = key.currentContext?.findRenderObject();

    // ignore: cast_nullable_to_non_nullable
    final RenderBox rootBox =
        origin.currentContext?.findRenderObject() as RenderBox;

    Offset? position;
    if (box != null) {
      position = (box as RenderBox).localToGlobal(Offset.zero,
          ancestor: rootBox); //this is global position
    }
    return position;
  }

  static Rect? getPositionRect(GlobalKey key, GlobalKey origin) {
    // ignore: cast_nullable_to_non_nullable
    final RenderObject? box = key.currentContext?.findRenderObject();

    if (box is RenderBox) {
      // ignore: cast_nullable_to_non_nullable
      final RenderBox rootBox =
          origin.currentContext!.findRenderObject() as RenderBox;

      final Offset position = box.localToGlobal(Offset.zero,
          ancestor: rootBox); //this is global position

      return Rect.fromLTWH(
          position.dx, position.dy, box.size.width, box.size.height);
    }

    return null;
  }
}
