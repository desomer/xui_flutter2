import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/application_manager.dart';

import '../../core/data/core_repository.dart';

class WidgetHiddenBox extends StatefulWidget {
  WidgetHiddenBox({super.key, required this.child});
  final Widget child;
  final ValueNotifier<bool> show = ValueNotifier<bool>(false);
  @override
  State<WidgetHiddenBox> createState() => _WidgetHiddenBoxState();
}

class _WidgetHiddenBoxState extends State<WidgetHiddenBox> {
  @override
  void initState() {
    super.initState();
    CWApplication.of().dataModelProvider.addUserAction('showAttr',
        CoreDataActionFunction((e) {
      widget.show.value = true;
    }));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.show,
        builder: (context, value, child) {
          return AnimatedContainer(
            // le detail des attribut
            duration: const Duration(milliseconds: 100),
            height: value ? 220 : 0,
            child: SingleChildScrollView(
                child: SizedBox(height: 220, child: widget.child)),
          );
        });
  }
}
