import 'core/data/core_data.dart';
import 'core/widget/cw_core_loader.dart';

class CWLoaderTest extends CWLoader {
  CWLoaderTest(super.ctx);

  @override
  CoreDataEntity getCWFactory() {
    setRoot('CWFrameDesktop');
    setProp(
        'root',
        ctxLoader.collectionWidget.createEntityByJson('CWFrameDesktop',
            <String, dynamic>{'title': 'un titre modifiable'}));

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
