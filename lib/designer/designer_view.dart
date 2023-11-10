import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_selector_overlay_action.dart';
import '../core/widget/cw_core_widget.dart';
import '../test_loader.dart';
import 'application_manager.dart';
import 'cw_factory.dart';
import 'designer.dart';

final log = Logger('DesignerView');

// ignore: must_be_immutable
class DesignerView extends StatefulWidget {
  DesignerView({super.key});

  DesignerViewState? state;

  @override
  State<StatefulWidget> createState() {
    return DesignerViewState();
  }

  CWWidgetLoader? loader;
  WidgetFactoryEventHandler get factory {
    return loader!.ctxLoader.factory;
  }

  Widget? rootWidget;

  void rebuild() {
    rootWidget = null;
    state?.stackDesigner = null;
    loader?.ctxLoader.factory.mapWidgetByXid.clear();
  }

  void repaintAll() {
    // ignore: invalid_use_of_protected_member
    CoreDesigner.of().designerKey.currentState?.setState(() {});
    for (var element in loader!.ctxLoader.factory.mapWidgetByXid.entries) {
      element.value.repaint();
    }
  }

  bool isLoad = false;
  Future<Widget> getPageRoot({ModeRendering? mode}) async {
    loader ??= CWLoaderTest(CWApplication.of().loaderDesigner);
    if (mode != null) {
      log.fine('set mode rendering $mode');
      loader?.ctxLoader.setModeRendering(mode);
    }

    if (!isLoad) {
      isLoad = true;
      log.fine('init event listener');
      CoreDesigner.on(CDDesignEvent.preview, (arg) {
        bool isPreviewMode = arg as bool;
        loader?.ctxLoader.setModeRendering(
            isPreviewMode ? ModeRendering.view : ModeRendering.design);
        log.fine('set mode rendering ${loader?.ctxLoader.mode}');
        rebuild();
        repaintAll();
      });
      await (loader as CWLoaderTest).loadCWFactory();
      await Future.delayed(const Duration(
          milliseconds: 500)); // pour faire apparaitre le tournicotton
      log.fine('get loadCWFactory from BDD OK');
    }

    if (rootWidget != null) return rootWidget!;

    log.fine('create root widget by browsing Json');
    rootWidget = loader!.getWidget('root', 'root');
    var app = CWApplication.of();
    // init les data models
    log.fine('init dataModel Provider for design');
    await app.dataModelProvider.getItemsCount((rootWidget as CWWidget).ctx);

    log.fine('init virtual widget');
    for (var widVir in loader!.ctxLoader.factory.mapWidgetVirtualByXid.values) {
      widVir.init();
    }

    return rootWidget!;
  }

  Widget getPageRootSync() {
    if (rootWidget != null) return rootWidget!;

    rootWidget = loader!.getWidget('root', 'root');
    return rootWidget!;
  }

  CWWidget? getWidgetByPath(String path) {
    return factory.mapWidgetByXid[factory.mapXidByPath[path] ?? ''];
  }
}

class DesignerViewState extends State<DesignerView> {
  Widget? stackDesigner;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    widget.state = this;
  }

  DevicePreview? preview;

  @override
  Widget build(BuildContext context) {
    FutureBuilder<Widget> futureBuilder = getFutureWidget();

    preview = DevicePreview(
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
          return stackDesigner!;
        });

    return LayoutBuilder(builder: (context, constraints) {
      stackDesigner ??= Stack(key: SelectorActionWidget.designerKey, children: [
        isInitialized ? widget.getPageRootSync() : futureBuilder,
        Positioned(
          left: 0,
          top: 0,
          child: SizedBox(
            key: SelectorActionWidget.scaleKeyMin,
            //color: Colors.red,
            height: 1,
            width: 1,
          ),
        ),
        Positioned(
          left: 100,
          top: 100,
          child: SizedBox(
            key: SelectorActionWidget.scaleKey2,
            //color: Colors.red,
            height: 1,
            width: 1,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: SizedBox(
            key: SelectorActionWidget.scaleKeyMax,
            //color: Colors.red,
            height: 1,
            width: 1,
          ),
        )
        // SelectorActionWidget(key: SelectorActionWidget.actionPanKey)
      ]);

      return Stack(children: [
        preview!,
        SelectorActionWidget(key: SelectorActionWidget.actionPanKey)
      ]);
    });
  }

  FutureBuilder<Widget> getFutureWidget() {
    var futureBuilder = FutureBuilder(
      future: widget.getPageRoot(),
      builder: (
        BuildContext context,
        AsyncSnapshot<Widget> snapshot,
      ) {
        //debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              strokeWidth: 10,
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
            ),
          ));
        } else if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            log.severe('error getPageRoot from BDD', snapshot.error, snapshot.stackTrace);
            return const Text('     Error');
          } else if (snapshot.hasData) {
            Future.delayed(const Duration(milliseconds: 100), () {
              CWWidget wid =
                  CoreDesigner.of().designView.factory.mapWidgetByXid['root']!;
              CoreDesigner.emit(CDDesignEvent.select, wid.ctx);
            });
            isInitialized = true;
            return snapshot.data!;
          } else {
            return const Text('Empty data');
          }
        } else {
          return Text('State: ${snapshot.connectionState}');
        }
      },
    );
    return futureBuilder;
  }
}
