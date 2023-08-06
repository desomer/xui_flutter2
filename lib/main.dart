// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:universal_html/html.dart' as html;
import 'package:xui_flutter/designer/application_manager.dart';
import 'core/data/core_data.dart';
import 'deprecated/_core_widget.dart';
import 'designer/designer.dart';

class MyErrorsHandler {
  initialize() {}

  onErrorDetails(FlutterErrorDetails details) {
    //FlutterError.presentError(details);
    debugPrint('onErrorDetails ${details.summary}');
  }

  onError(Object error, StackTrace stack) {
    debugPrint('onError $error $stack');
  }
}

// mongo    gauthierdesomer   xRyLG1bVzc8IproW

void main() async {
  var myErrorsHandler = MyErrorsHandler();

  await myErrorsHandler.initialize();

  CWApplication.of().initDesigner();
  CWApplication.of().initModel();

  WidgetsFlutterBinding.ensureInitialized();

  //*_r$y-74WSMFKk8
  //await supabase();

  //StartMongo().init();

  runApp(CoreDesigner());

  html.document.onContextMenu
      .listen((html.MouseEvent event) => event.preventDefault());
  //runApp(const MyApp());
}



class FavoriteWidget extends StatefulWidget {
  FavoriteWidget({super.key});

  final FavoriteWidgetState st = FavoriteWidgetState();

  @override
  State<FavoriteWidget> createState() {
    // ignore: no_logic_in_create_state
    return st;
  }
}

class FavoriteWidgetState extends State<FavoriteWidget> {
  // bool _isFavorited = true;
  // int _favoriteCount = 41;
  int nb = 2;

  Widget getRoot() {
    final CoreDataCollection collection = CoreDataCollection();
    final CoreDataObjectBuilder txt = collection.addObject('Text');
    txt.addAttribut('data', CDAttributType.CDtext);
    txt.addAttribut('style', CDAttributType.CDone, tname: 'TextStyle');

    final CoreDataObjectBuilder st = collection.addObject('TextStyle');
    st.addAttribut('color', CDAttributType.CDtext);
    st.addAttribut('fontSize', CDAttributType.CDdec);

    collection.addObject('Widget');

    final CoreDataObjectBuilder col = collection.addObject('Column');
    col.addAttribut('children', CDAttributType.CDmany, tname: 'Widget');

    //-----------------------------------------------------
    final CoreDataEntity aCol = collection.getClass('Column')!.createEntity();

    final CoreDataEntity aTxt = collection
        .getClass('Text')!
        .createEntity()
        .setAttr(collection, 'data', '0')
        .setAttr(collection, 'style', '1');

    final CoreDataEntity style = collection
        .getClass('TextStyle')!
        .createEntity()
        .setAttr(collection, 'color', 'ffff00ff');

    collection
        .getClass('Text')!
        .createEntity()
        .setAttr(collection, 'data', 'toto');

    aTxt.setOne(collection, 'style', style);
    aCol.addMany(collection, 'children', aTxt);
    // aCol.addMany(collection, 'children', aTxt2);
    for (int i = 0; i < nb; i++) {
      aCol.addMany(
          collection,
          'children',
          // ignore: always_specify_types
          collection.createEntityByJson('Text', {
            'data': 'eee$i',
            'style': {r'$type': 'TextStyle', 'color': 'ff0000ff'}
          }));
    }

    //------------------------------------------------------------
    aCol.prepareChange(collection);
    aTxt.setAttr(collection, 'data', 'click');
    doPrintObject('fff ', aCol);

    aCol.prepareChange(collection);
    aTxt.setAttr(collection, 'data', 'tutu');
    doPrintObject('fff2 ', aCol);
    aCol.prepareChange(collection);
    aCol.undoChange(collection);
    doPrintObject('undo', aCol);

    aCol
        .getPath(collection, 'children[0]')
        .entities
        .last
        .getOne(collection, 'style', 'TextStyle')
        .setAttr(collection, 'color', '00fff0ff')
        .setAttr(collection, 'fontSize', 46);

    aCol.prepareChange(collection);

    aCol
        .getPath(collection, 'children[2]')
        .entities
        .last
        .getOne(collection, 'style', 'TextStyle')
        .setAttr(collection, 'fontSize', 30);

//    aCol.prepareChange(collection);
    // aCol.undoChange(collection);
    // aCol.undoChange(collection);
    // aCol.undoChange(collection);

    doPrintObject('', aCol);

    final CoreDataCtx ctx = CoreDataCtx();
    ctx.browseHandler = CoreWidgetFactoryEventHandler();
    aCol.browse(collection, ctx);

    // final CoreDataPath path = aCol.getPath(collection, 'children[2]');
    // print('path${path.entities.last}');

    final Widget root =
        (ctx.browseHandler as CoreWidgetFactoryEventHandler).root!;

    return root;
  }

  void doPrintObject(String msg, CoreDataEntity i) {
    doTrace('$msg ret= $i diff=${i.getDiff()} orignal=${i.original ?? "null"}');
  }

  void doTrace(String str) {
    debugPrint(str);
  }

  @override
  Widget build(BuildContext context) {
    return getRoot();

    // return Row(
    //   mainAxisSize: MainAxisSize.min,
    //   children: [
    //     Container(
    //       padding: const EdgeInsets.all(0),
    //       child: IconButton(
    //         padding: const EdgeInsets.all(0),
    //         alignment: Alignment.centerRight,
    //         icon: (_isFavorited
    //             ? const Icon(Icons.star)
    //             : const Icon(Icons.star_border)),
    //         color: Colors.red[500],
    //         onPressed: _toggleFavorite,
    //       ),
    //     ),
    //     SizedBox(
    //       width: 18,
    //       child: SizedBox(
    //         child: Text('$_favoriteCount'),
    //       ),
    //     ),
    //   ],
    // );
  }

  void toggleFavorite() {
    setState(() {
      nb = nb + 1;
      // if (_isFavorited) {
      //   _favoriteCount -= 1;
      //   _isFavorited = false;
      // } else {
      //   _favoriteCount += 1;
      //   _isFavorited = true;
      // }
    });
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double s = 10;

  void doBtn() {
    //getRoot();
    fabv.st.toggleFavorite();
  }

  // i.undoChange(o1);
  // i.prepareChange(o1);
  // i.setValue(o1, 'y', '2');
  // doPrintObject('set y 2', i, o1);
  // i.undoChange(o1);
  // doPrintObject('undo', i, o1);
  // i.redoChange(o1);
  // doPrintObject('redo', i, o1);
  // i.undoChange(o1);
  // i.prepareChange(o1);
  // i.setValue(o1, 'x', '2');
  // i.setValue(o1, 'y', '3');
  // doPrintObject('set 2 3', i, o1);
  // i.undoChange(o1);
  // doPrintObject('undo', i, o1);
  // i.redoChange(o1);
  // doPrintObject('redo', i, o1);
  // i.undoChange(o1);
  // doPrintObject('undo', i, o1);
  // i.undoChange(o1);
  // doPrintObject('undo', i, o1);
  // i.undoChange(o1);
  // doPrintObject('undo', i, o1);

  FavoriteWidget fabv = FavoriteWidget();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Elisys XUI',
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter FlatButton Example'),
          ),

          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        color: Colors.red,
                        child: const Column(
                          children: <Widget>[
                            Text('Left', textAlign: TextAlign.center),
                            Text('Left', textAlign: TextAlign.center),
                            Text('Left', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.green,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text('Right', textAlign: TextAlign.center),
                            Text('Right', textAlign: TextAlign.center),
                            Text('Right', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded(
              //   // child: Container(color: Colors.blue, child: CWTab(nb: 2)
              //       // child: WidgetSizeOffsetWrapper(
              //       //     onSizeChange: (Size size) {
              //       //       print('Size: ${size.width}, ${size.height}');
              //       //       // setState(() {
              //       //       //   s = size.height - 22;
              //       //       // });
              //       //     },
              //       //     child: LayoutBuilder(builder:
              //       //     (BuildContext context, BoxConstraints viewportConstraints)
              //       //     {
              //       //       print('context A '+context.toString());
              //       //       print('viewportConstraints A '+viewportConstraints.toString());
              //       //       return Column(
              //       //       mainAxisAlignment: MainAxisAlignment.start,
              //       //       children: <Widget>[getB(viewportConstraints.maxHeight)],
              //       //     );
              //       //     })
              //       //     ),
              //       ),
              // ),
            ],
          ),

          //getB()
        ));
  }

  final GlobalKey _widgetKey = GlobalKey();

  DefaultTabController getB(double h) {
    return
        // fabv,
        DefaultTabController(
            length: 2,
            child: Column(children: <Widget>[
              SizedBox(
                height: 22,
                child: Container(
                    color: Colors.yellow,
                    child: const TabBar(
                      tabs: [
                        Tab(
                          height: 20,
                          icon: Icon(Icons.directions_bike, size: 18),
                        ),
                        Tab(
                          height: 20,
                          icon: Icon(
                            Icons.directions_car,
                            size: 18,
                          ),
                        ),
                      ],
                    )),
              ),
              LayoutBuilder(builder:
                  (BuildContext context, BoxConstraints viewportConstraints) {
                debugPrint(context.toString());
                debugPrint(viewportConstraints.toString());
                return SingleChildScrollView(
                    child: SizedBox(
                  key: _widgetKey,
                  height: h + 300,
                  child: TabBarView(
                    children: [
                      // first tab bar view widget
                      Container(
                        color: Colors.red,
                        child: const Center(
                          child: Text(
                            'Bike',
                          ),
                        ),
                      ),

                      // second tab bar viiew widget
                      Container(
                        color: Colors.pink,
                        child: const Center(
                          child: Text(
                            'Car',
                          ),
                        ),
                      ),
                    ],
                  ),
                ));
              })
            ]));
    // Container(
    //   margin: const EdgeInsets.all(25),
    //   child: ElevatedButton(
    //     child: const Text(
    //       'SignUp',
    //       style: TextStyle(fontSize: 20.0),
    //     ),
    //     onPressed: () {
    //       doBtn();
    //     },
    //   ),
    // ),
  }
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
