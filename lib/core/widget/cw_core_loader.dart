import '../data/core_data.dart';

class CWLoader {
  CoreDataEntity getFrame(CoreDataCollection collection) {
    final CoreDataEntity aFrame = collection.createEntity('CWFrame');

    aFrame.setOne(
        collection,
        'child',
        collection.createEntityByJson('CWChild',
            <String, dynamic>{'xid': 'root', 'implement': 'CWFrameDesktop'}));

    final CoreDataEntity aFrameDesktop = collection.createEntityByJson(
        'CWFrame', <String, dynamic>{'title': 'un titre modifiable'});

    aFrame.addMany(
        collection,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(collection, 'xid', 'root')
            .setOne(collection, 'properties', aFrameDesktop));

    aFrame.addMany(
        collection,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(collection, 'xid', 'rootBody')
            .setOne(
                collection,
                'child',
                collection.createEntityByJson('CWChild',
                    <String, dynamic>{'xid': 'tab1', 'implement': 'CWTab'})));

    final CoreDataEntity aTab =
        collection.createEntityByJson('CWTab', <String, dynamic>{'nb': 3});

    aFrame.addMany(
        collection,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(collection, 'xid', 'tab1')
            .setOne(collection, 'properties', aTab));

    aFrame.addMany(
        collection,
        'designs',
        collection
            .createEntity('CWDesign')
            .setAttr(collection, 'xid', 'tab1Cont1')
            .setOne(
                collection,
                'child',
                collection.createEntityByJson('CWChild', <String, dynamic>{
                  'xid': 'tabInner',
                  'implement': 'CWTab'
                })));

    return aFrame;
  }
}
