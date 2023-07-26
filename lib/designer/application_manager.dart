import '../core/data/core_data.dart';
import '../core/data/core_data_loader.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import 'cw_factory.dart';
import 'designer_model.dart';

class CWApplication {
  static final CWApplication _current = CWApplication();
  static CWApplication of() {
    return _current;
  }

  CWWidgetLoaderCtx loaderDesigner = CWWidgetLoaderCtx();
  CWWidgetLoaderCtx loaderModel = CWWidgetLoaderCtx();
  CWWidgetLoaderCtx loaderAttribut = CWWidgetLoaderCtx();
  CWWidgetLoaderCtx loaderData = CWWidgetLoaderCtx();

  CoreDataCollection collection = CoreDataCollection();

  CWProvider dataModelProvider =
      CWProvider("DataModelProvider", "DataModel", null);
  late CWProvider dataAttributProvider;

  initDesigner() {
    loaderDesigner.collectionWidget = CWCollection().collection;
    loaderDesigner.collectionDataModel = loaderDesigner.collectionWidget;
    loaderDesigner.mode = ModeRendering.design;
    loaderDesigner.entityCWFactory =
        loaderDesigner.collectionWidget.createEntity('CWFactory');
    loaderDesigner.factory = WidgetFactoryEventHandler(loaderDesigner);

    loaderModel.collectionWidget = loaderDesigner.collectionWidget;
    loaderModel.createFactory();

    loaderAttribut.collectionWidget = loaderDesigner.collectionWidget;
    loaderAttribut.createFactory();

    loaderData.collectionWidget = loaderDesigner.collectionWidget;
    loaderData.createFactory();
  }

  initModel() {
    loaderModel.mode = ModeRendering.view;
    loaderModel.collectionDataModel = collection;

    loaderAttribut.mode = ModeRendering.view;
    loaderAttribut.collectionDataModel = collection;

    loaderData.mode = ModeRendering.view;

    collection.addObject("DataModel")
      ..addAttribut("name", CDAttributType.CDtext)
      ..addAttribut("listAttr", CDAttributType.CDmany);

    collection.addObject("ModelAttributs")
      ..addAttribut("name", CDAttributType.CDtext)
      ..addAttribut("type", CDAttributType.CDtext);

    CoreDataEntity entity1 =
        collection.createEntityByJson("DataModel", {"name": "Customers"});

    CoreDataEntity entity2 =
        collection.createEntityByJson("DataModel", {"name": "Pets"});

    entity1.addMany(
        collection,
        "listAttr",
        collection.createEntityByJson(
            "ModelAttributs", {"name": "First name", "type": "TEXT"}));
    entity1.addMany(
        collection,
        "listAttr",
        collection.createEntityByJson(
            "ModelAttributs", {"name": "Last name", "type": "TEXT"}));

    entity2.addMany(
        collection,
        "listAttr",
        collection.createEntityByJson(
            "ModelAttributs", {"name": "Name", "type": "TEXT"}));
    entity2.addMany(
        collection,
        "listAttr",
        collection.createEntityByJson(
            "ModelAttributs", {"name": "Category", "type": "TEXT"}));
    entity2.addMany(
        collection,
        "listAttr",
        collection.createEntityByJson(
            "ModelAttributs", {"name": "Breed", "type": "TEXT"}));

    initProvider(entity1, entity2);
  }

  void initProvider(CoreDataEntity entity1, CoreDataEntity entity2) {
    dataModelProvider.header =
        collection.createEntityByJson("DataModel", {"label": "Entity"});

    dataModelProvider
      ..add(entity1)
      ..add(entity2);
    dataModelProvider.idxSelected = 0;

    dataModelProvider.addAction(
        CWProviderAction.onInsertNone, OnInsertModel(loaderModel));
    dataModelProvider.addAction(CWProviderAction.onBuild, OnBuild());

    dataModelProvider.addAction(CWProviderAction.onSelected, OnSelectModel());

    //----------------------------------------------
    dataAttributProvider = CWProvider("DataAttrProvider", "ModelAttributs",
        CoreDataLoaderProvider(loaderAttribut, dataModelProvider, "listAttr"));
  }
}
