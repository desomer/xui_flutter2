import 'dart:async';

import 'package:flutter/material.dart';

import '../../widget/cw_frame_desktop.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;
  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  bool mustVisible(State state) {
    bool display = true;
    if (DateTime.now().millisecondsSinceEpoch - CWFrameDesktop.timeResize <
        200) {
      display = false;
      run(() {
        if (state.mounted) {
          // ignore: invalid_use_of_protected_member
          state.setState(() {});
        }
      });
    }
    return display;
  }
}
