import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:xui_flutter/designer/widget_filter_builder.dart';

import '../core/data/core_data_filter.dart';
import '../core/data/core_provider.dart';
import '../core/store/driver.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_selector_overlay_action.dart';
import '../core/widget/cw_core_widget.dart';
import '../test_loader.dart';
import 'application_manager.dart';
import 'cw_factory.dart';
import 'designer.dart';
import 'designer_selector_component.dart';
import 'designer_selector_pages.dart';
import 'designer_selector_properties.dart';
import 'designer_selector_provider.dart';
import 'designer_selector_query.dart';
import 'widget/widget_tab.dart';

final log = Logger('DesignerPageEditor');

// ignore: must_be_immutable
class DesignerEditor extends StatelessWidget {
  DesignerEditor({super.key});

  late TabController controllerTabRight;
  late TabController controllerTabResult;

  final ScrollController scrollComponentController = ScrollController(
    initialScrollOffset: 0.0,
    keepScrollOffset: true,
  );

  final ScrollController scrollPropertiesController = ScrollController(
    initialScrollOffset: 0.0,
    keepScrollOffset: true,
  );

  final ScrollController scrollResultController = ScrollController(
    initialScrollOffset: 0.0,
    keepScrollOffset: true,
  );

  final ScrollController scrollResultAttributController = ScrollController(
    initialScrollOffset: 0.0,
    keepScrollOffset: true,
  );

  @override
  Widget build(BuildContext context) {
    CWWidgetCtx ctxQuery = CWWidgetCtx('', CWApplication.of().loaderModel, '');
    ctxQuery.designEntity = CWApplication.of()
        .loaderModel
        .collectionWidget
        .createEntityByJson('CWArray', {iDProviderName: 'DataModelProvider'});

    CWWidgetCtx ctxResult = CWWidgetCtx('', CWApplication.of().loaderModel, '');
    // ctxQuery.designEntity = CWApplication.of()
    //     .loaderModel
    //     .collectionWidget
    //     .createEntityByJson('CWArray', {iDProviderName: 'ResultProvider'});

    CWWidgetCtx ctxPages = CWWidgetCtx('', CWApplication.of().loaderModel, '');
    ctxPages.designEntity = CWApplication.of()
        .loaderModel
        .collectionWidget
        .createEntityByJson('CWArray', {iDProviderName: 'PagesProvider'});

    return Row(children: [
      SizedBox(
        width: 300,
        child: WidgetTab(heightTab: 40, listTab: const [
          Tab(icon: Tooltip(message: 'Navigation', child: Icon(Icons.near_me))),
          Tab(icon: Tooltip(message: 'Data', child: Icon(Icons.manage_search)))
        ], listTabCont: [
          DesignerPages(ctx: ctxPages),
          Column(
            children: [
              Expanded(
                  child: DesignerQuery(
                      key: CoreDesigner.of().queryKey,
                      mode: FilterBuilderMode.selector,
                      ctx: ctxQuery)),
              const Divider(thickness: 1, height: 1),
              Expanded(child: getResultProperties(ctxResult))
            ],
          )
        ]),
      ),
      Expanded(child: CoreDesigner.of().designView),
      SizedBox(width: 300, child: getTabProperties())
    ]);
  }

  Widget getResultProperties(CWWidgetCtx ctxResult) {
    final List<Widget> listTab = <Widget>[];
    listTab.add(const Tab(
      icon: Icon(Icons.saved_search_rounded),
    ));

    listTab.add(const Tab(
      icon: Icon(Icons.data_object_rounded),
    ));

    final List<Widget> listTabCont = <Widget>[];

    return LayoutBuilder(builder: (context, constraints) {
      listTabCont.add(SingleChildScrollView(
          controller: scrollResultController,
          scrollDirection: Axis.vertical,
          child: SizedBox(
              height: constraints.maxHeight - 45,
              child: DesignerProvider(
                  key: CoreDesigner.of().providerKey, ctx: ctxResult))));

      listTabCont.add(SingleChildScrollView(
          controller: scrollResultAttributController,
          scrollDirection: Axis.vertical,
          child: Container())); // const Steps());

      return WidgetTab(
          heightTab: 40,
          onController: (TabController a) {
            controllerTabResult = a;
          },
          listTab: listTab,
          listTabCont: listTabCont);
    });
  }

  Widget getTabProperties() {
    final List<Widget> listTab = <Widget>[];
    listTab.add(const Tab(
      // height: 30,
      icon: Icon(Icons.edit_note),
    ));

    listTab.add(const Tab(
      // height: 30,
      icon: Icon(Icons.widgets),
    ));

    final List<Widget> listTabCont = <Widget>[];

    listTabCont.add(SingleChildScrollView(
        //key: const PageStorageKey<String>('pageProp'),
        controller: scrollPropertiesController,
        scrollDirection: Axis.vertical,
        child: DesignerProp(key: CoreDesigner.of().propKey)));

    listTabCont.add(SingleChildScrollView(
        //key: const PageStorageKey<String>('pageWidget'),
        controller: scrollComponentController,
        scrollDirection: Axis.vertical,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ComponentDesc.getListComponent))); // const Steps());

    return WidgetTab(
        heightTab: 40,
        onController: (TabController a) {
          controllerTabRight = a;
        },
        listTab: listTab,
        listTabCont: listTabCont);
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
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

  void clearAll() {
    rebuild();
    loader = null;
    isLoad = false;
    var loaderDesigner = CWApplication.of().loaderDesigner;
    loaderDesigner.entityCWFactory =
        loaderDesigner.collectionWidget.createEntity('CWFactory');
    loaderDesigner.factory = WidgetFactoryEventHandler(loaderDesigner);
    loaderDesigner.setModeRendering(ModeRendering.design);
  }

  void repaintAll() {
    // ignore: invalid_use_of_protected_member
    CoreDesigner.of().designerKey.currentState?.setState(() {});
    for (var element in loader!.ctxLoader.factory.mapWidgetByXid.entries) {
      element.value.repaint();
    }
  }

  bool isLoad = false;
  bool isEventInit = false;

  Future<Widget> getPageRoot({ModeRendering? mode}) async {
    loader ??= CWLoaderTest(CWApplication.of().loaderDesigner);
    if (mode != null) {
      log.fine('set mode rendering $mode');
      loader?.ctxLoader.setModeRendering(mode);
    }

    if (!isEventInit) {
      isEventInit = true;
      log.fine('init event listener');
      CoreDesigner.on(CDDesignEvent.preview, (arg) {
        bool isPreviewMode = arg as bool;
        loader?.ctxLoader.setModeRendering(
            isPreviewMode ? ModeRendering.view : ModeRendering.design);
        log.fine('set mode rendering ${loader?.ctxLoader.mode}');
        rebuild();
        repaintAll();
        Future.delayed(const Duration(milliseconds: 100), () {
           CoreDesigner.emit(CDDesignEvent.reselect, 'redisplayProp');
        });
      });
    }

    if (!isLoad) {
      isLoad = true;
      await (loader as CWLoaderTest).loadCWFactory();
      // await Future.delayed(const Duration(
      //     milliseconds: 500)); // pour faire apparaitre le tournicotton
      log.fine('get loadCWFactory from BDD OK');
    }

    if (rootWidget == null) {
      log.fine('create root widget by browsing Json');
      rootWidget = loader!.getWidget('root', 'root');
      var app = CWApplication.of();
      // init les data models
      log.fine('init dataModels Provider for design');
      await app.dataModelProvider.getItemsCount((rootWidget as CWWidget).ctx);

      log.fine('init dataFilters for design');
      StoreDriver storage = await StoreDriver.getDefautDriver('main')!;
      var filters = await storage.getJsonData('filters', null);
      List<dynamic> listFilter = filters['listData'];
      for (var aFilterData in listFilter) {
        var aFilter = CoreDataFilter();
        aFilter.createFilterWithData(aFilterData);
        CWApplication.of().mapFilters[aFilter.dataFilter.value['_id_']] =
            aFilter;
      }

      log.fine('init virtual widget');
      for (var widVir
          in loader!.ctxLoader.factory.mapWidgetVirtualByXid.values) {
        widVir.init();
      }
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
            log.severe('error getPageRoot from BDD', snapshot.error,
                snapshot.stackTrace);
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
