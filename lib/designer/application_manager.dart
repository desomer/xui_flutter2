import '../core/data/core_data.dart';
import '../core/data/core_data_loader.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_loader.dart';
import '../core/widget/cw_core_widget.dart';
import 'cw_factory.dart';
import 'designer_data.dart';
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
  late CWProvider dataProvider;

  Map<String, CoreDataEntity> listData = {};

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
    loaderData.collectionDataModel = collection;

    collection
        .addObject("DataEntity")
        .addAttr("_id_", CDAttributType.CDtext)
        .withAction(AttrActionDefaultUUID())
        .addAttr("_createAt_", CDAttributType.CDdate)
        .addAttr("_updateAt_", CDAttributType.CDdate);

    collection
        .addObject("DataModel")
        .addAttr("name", CDAttributType.CDtext)
        .addAttr("listAttr", CDAttributType.CDmany)
        .addGroup(collection.getClass("DataEntity")!);

    collection.addObject("DataHeader").addAttr("label", CDAttributType.CDtext);

    collection
        .addObject("DataContainer")
        .addAttr("name", CDAttributType.CDtext)
        .addAttr("listData", CDAttributType.CDmany);

    collection
        .addObject("ModelAttributs")
        .addAttr("_id_", CDAttributType.CDtext)
        .withAction(AttrActionDefaultUUID())        
        .addAttr("name", CDAttributType.CDtext)
        .addAttr("type", CDAttributType.CDtext);



    initProvider();

    //////////////////////////////////
    initPetStore();
  }

  void initPetStore() {
    CoreDataEntity modelCustomer =
        collection.createEntityByJson("DataModel", {"name": "Customers"});

    CoreDataEntity modelPets =
        collection.createEntityByJson("DataModel", {"name": "Pets"});

    //////////////////////////////////////////
    modelCustomer.addMany(
        collection,
        "listAttr",
        collection.createEntityByJson(
            "ModelAttributs", {"name": "First name", "type": "TEXT"}));
    modelCustomer.addMany(
        collection,
        "listAttr",
        collection.createEntityByJson(
            "ModelAttributs", {"name": "Last name", "type": "TEXT"}));
    /////////////////////////////////////////////////
    modelPets.addMany(
        collection,
        "listAttr",
        collection.createEntityByJson(
            "ModelAttributs", {"name": "Name", "type": "TEXT"}));
    modelPets.addMany(
        collection,
        "listAttr",
        collection.createEntityByJson(
            "ModelAttributs", {"name": "Category", "type": "TEXT"}));
    modelPets.addMany(
        collection,
        "listAttr",
        collection.createEntityByJson(
            "ModelAttributs", {"name": "Breed", "type": "TEXT"}));

    /////////////////////////////////////
    dataModelProvider
      ..add(modelCustomer)
      ..add(modelPets);
  }

  void initProvider() {
    dataModelProvider.header =
        collection.createEntityByJson("DataHeader", {"label": "Entity"});

    dataModelProvider.idxSelected = 0;

    dataModelProvider.addAction(
        CWProviderAction.onInsertNone, OnInsertModel(loaderModel));
    dataModelProvider.addAction(CWProviderAction.onBuild, OnBuildEdit(["name"], false));
    dataModelProvider.addAction(CWProviderAction.onSelected, OnSelectModel());

    //----------------------------------------------
    dataAttributProvider = CWProvider("DataAttrProvider", "ModelAttributs",
        CoreDataLoaderNested(loaderAttribut, dataModelProvider, "listAttr"));

    dataAttributProvider.header =
        collection.createEntityByJson("DataHeader", {"label": "?"});

    dataAttributProvider.addAction(
        CWProviderAction.onBuild, OnBuildEdit(["name"], false));
    dataAttributProvider.addAction(
        CWProviderAction.onInsertNone, OnAddAttr(dataAttributProvider));
    //-------------------------------------------------------
    dataProvider = CWProvider("DataProvider", "?",
        CoreDataLoaderMap(loaderData, listData, "listData"));
    dataProvider.header =
        collection.createEntityByJson("DataHeader", {"label": "?"});

    dataProvider.addAction(CWProviderAction.onBuild, OnBuildEdit(["*"], true));
    dataProvider.addAction(
        CWProviderAction.onInsertNone, OnInsertData());
    dataProvider.addAction(
        CWProviderAction.onNone2Create, SetDate("_createAt_"));
    dataProvider.addAction(
        CWProviderAction.onChange, SetDate("_updateAt_"));
  }
}
