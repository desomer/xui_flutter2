import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_selector_action.dart';
import '../core/widget/cw_core_widget.dart';
import '../test_loader.dart';
import 'application_manager.dart';
import 'cw_factory.dart';

// ignore: must_be_immutable
class DesignerView extends StatefulWidget {
  DesignerView({super.key});

  @override
  State<StatefulWidget> createState() => DesignerViewState();

  late CWWidgetLoader loader;
  WidgetFactoryEventHandler get factory {
    return loader.ctxLoader.factory;
  }

  Widget? rootWidget;

  Widget getRoot() {
    if (rootWidget != null) return rootWidget!;

    loader = CWLoaderTest(CWApplication.of().loaderDesigner);
    rootWidget = loader.getWidget("root", "root");
    return rootWidget!;
  }

  CWWidget? getWidgetByPath(String path) {
    return factory.mapWidgetByXid[factory.mapXidByPath[path] ?? ""];
  }
}

class DesignerViewState extends State<DesignerView> {
  Widget? stack;

  @override
  Widget build(BuildContext context) {
    stack ??= Stack(key: SelectorActionWidget.designerKey, children: [
      widget.getRoot(),
      SelectorActionWidget(key: SelectorActionWidget.actionPanKey)
    ]);

    var preview = DevicePreview(
        storage: DevicePreviewStorage.none(),
        backgroundColor: Colors.black,
        enabled: true,
        isToolbarVisible: true,
        tools: const [
          DeviceSection(),
          //SystemSection(),
          // AccessibilitySection(),
          //SettingsSection()
        ],
        data: DevicePreviewData(
            deviceIdentifier: Devices.ios.iPhone13.toString(),
            isFrameVisible: false,
            locale: 'fr_FR',
            isDarkMode: true,
            settings: const DevicePreviewSettingsData(
                toolbarTheme: DevicePreviewToolBarThemeData.dark,
                backgroundTheme: DevicePreviewBackgroundThemeData.dark,
                toolbarPosition: DevicePreviewToolBarPositionData.left)),
        builder: (context) {
          return stack!;
        });

    return preview;
  }
}
