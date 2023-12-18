import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:universal_html/html.dart' as html;
import 'package:xui_flutter/designer/application_manager.dart';
import 'core/store/driver.dart';
import 'core/widget/cw_core_widget.dart';
import 'designer/designer.dart';

class MyErrorsHandler {
  void initialize() {}

  void onErrorDetails(
    FlutterErrorDetails details, {
    bool forceReport = false,
  }) {
    bool ifIsOverflowError = false;
    bool isUnableToLoadAsset = false;

    // Detect overflow error.
    var exception = details.exception;
    if (exception is FlutterError) {
      ifIsOverflowError = !exception.diagnostics.any(
        (e) => e.value.toString().startsWith('A RenderFlex overflowed by'),
      );
      isUnableToLoadAsset = !exception.diagnostics.any(
        (e) => e.value.toString().startsWith('Unable to load asset'),
      );
    }

    // Ignore if is overflow error.
    if (ifIsOverflowError || isUnableToLoadAsset) {
      debugPrint('Ignored Error');
    } else {
      FlutterError.presentError(details);
      //FlutterError.dumpErrorToConsole(details, forceReport: forceReport);
    }
  }

  void onError(Object error, StackTrace stack) {
    debugPrint('onError $error $stack');
  }
}

// mongo    gauthierdesomer   xRyLG1bVzc8IproW

final log = Logger('main.dart');
final DateFormat formatter = DateFormat('HH:mm:ss');

var reset = '\x1B[0m';
var black = '\x1B[30m';
var white = '\x1B[37m';
var red = '\x1B[31m';
var green = '\x1B[32m';
var yellow = '\x1B[33m';
var blue = '\x1B[34m';
var cyan = '\x1B[36m';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print

    // ignore: avoid_print
    print(
        '$white${formatter.format(record.time)}-${record.time.millisecond.toString().padLeft(3, '0')}$reset [$green${record.loggerName.padRight(20)}$reset] ${record.level.name.padRight(6)}: $yellow${record.message}$reset');

    // ignore: avoid_print
    if (record.error != null) print('$red${record.error}');
    // ignore: avoid_print
    if (record.stackTrace != null) print(record.stackTrace);
  });

  // var myErrorsHandler = MyErrorsHandler();
  // myErrorsHandler.initialize();

  // FlutterError.onError = myErrorsHandler.onErrorDetails;

  // PlatformDispatcher.instance.onError = (error, stack) {
  //   myErrorsHandler.onError(error, stack);
  //   return true;
  // };

  //ErrorWidget.builder = (FlutterErrorDetails details) => Container();

  CWApplication.of().initWidgetLoader();
  CWApplication.of().initModel();

  await StoreDriver.getDefautDriver('main');

  //*_r$y-74WSMFKk8
  //await supabase();
  //StartMongo().init();

  CoreDesigner();
  Widget view = CoreDesigner.of();
  bool modeview = const bool.fromEnvironment('modeview', defaultValue: false);
  if (modeview) {
    view = await CoreDesigner.of()
        .designView
        .getPageRoot(mode: ModeRendering.view);
  }
  log.info('runApp');

  runApp(view);

  html.document.onContextMenu
      .listen((html.MouseEvent event) => event.preventDefault());
}

typedef OnWidgetSizeChange = void Function(Size size);

class WidgetSizeRenderObject extends RenderProxyBox {
  WidgetSizeRenderObject(this.onSizeChange);
  final OnWidgetSizeChange onSizeChange;
  Size? currentSize;

  @override
  void performLayout() {
    super.performLayout();

    try {
      Size? newSize = child?.size;

      if (newSize != null && currentSize != newSize) {
        currentSize = newSize;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onSizeChange(newSize);
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  dynamic overriddenSymbolFrom(dynamic classType, String name) {
    if (classType.isUnknown()) {
      return classType.unknownMethodSymbol;
    }
    bool unknownFound = false;
    List<dynamic> symbols = classType.getSymbol().members().lookup(name);
    for (dynamic overrideSymbol in symbols) {
      if (overrideSymbol.isKind('') && !overrideSymbol.isStatic()) {
        dynamic methodJavaSymbol = overrideSymbol;
        if (methodJavaSymbol.canOverride(methodJavaSymbol)) {
          dynamic overriding =
              classType.checkOverridingParameters(methodJavaSymbol, classType);
          if (overriding == null) {
            if (!unknownFound) {
              unknownFound = true;
              if (classType.checkOverridingParameters(
                      methodJavaSymbol, classType) &&
                  !overrideSymbol.isStatic()) {
                if (unknownFound) {
                  unknownFound = true;
                }
              }
            }
          } else if (overriding) {
            return methodJavaSymbol;
          }
        }
      }
    }
    if (unknownFound) {
      return classType.unknownMethodSymbol;
    }
    return null;
  }
}

class WidgetSizeOffsetWrapper extends SingleChildRenderObjectWidget {
  const WidgetSizeOffsetWrapper({
    super.key,
    required this.onSizeChange,
    required Widget super.child,
  });
  final OnWidgetSizeChange onSizeChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return WidgetSizeRenderObject(onSizeChange);
  }
}
