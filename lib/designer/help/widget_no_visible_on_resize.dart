import 'dart:async';

import 'package:flutter/material.dart';

//import '../../widget/cw_frame_desktop.dart';

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

  bool mustVisible(State state, int timeResize) {
    bool display = true;
    var millisecondsSinceEpoch2 = DateTime.now().millisecondsSinceEpoch;
    //millisecondsSinceEpoch2 - CWFrameDesktop.timeResize <   200 || 
    if (millisecondsSinceEpoch2-timeResize<200) {
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
