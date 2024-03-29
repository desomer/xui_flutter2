import 'core/data/core_data.dart';
import 'core/store/driver.dart';
import 'core/widget/cw_core_loader.dart';

class CWLoaderTest extends CWWidgetLoader {
  CWLoaderTest(super.ctx);

  bool loadEmpty = true;

  @override
  Future<CoreDataEntity> loadCWFactory() async {
    StoreDriver? storage = await StoreDriver.getDefautDriver('main');
    dynamic v = await storage?.getJsonData('#pages', null);
    if (v != null) {
      cwFactory.value = v;
      loadEmpty = false;
    }
    return cwFactory;
  }

  @override
  CoreDataEntity initCWFactory() {
    if (loadEmpty) {
      loadEmpty = false;
      setRoot('root', 'CWApp');
      // setProp(
      //     'root',
      //     ctxLoader.collectionWidget.createEntityByJson(
      //         'CWApp', <String, dynamic>{}));      
      setConstraint(
          'rootPagePagehome',
          ctxLoader.collectionWidget.createEntityByJson(
              'CWPageConstraint', <String, dynamic>{'fill': true}));
    }

    //------------------------------------------------------------------
    // addChildProp(
    //     'rootBody',
    //     'tab1',
    //     'CWTab',
    //     ctxLoader.collection
    //         .createEntityByJson('CWTab', <String, dynamic>{'tabCount': 3}));

    // //----------------------------------------------------
    // addChildProp(
    //     'tab1Cont0',
    //     'aText',
    //     'CWTextfield',
    //     ctxLoader.collection.createEntityByJson(
    //         'CWTextfield', <String, dynamic>{'label': 'un label'}));

    // //----------------------------------------------------
    // addChild('tab1Cont1', 'tabInner', 'CWTab');

    return cwFactory;
  }
}
