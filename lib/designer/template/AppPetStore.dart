import '../../core/data/core_data.dart';

class AppPetStore {

  void initPetStore(CoreDataCollection collection) {
    // final LocalStorage storage = LocalStorage('listModel.json');
    // await storage.ready;
    // await Future.delayed(const Duration(seconds: 5));
    // var items = storage.getItem('data');
    // var items;

    // if (items == null) {
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
    // dataModelProvider
    //   ..add(modelCustomer)
    //   ..add(modelPets);

    CoreDataEntity modelContainer = collection.createEntityByJson(
        "DataContainer", {"idData": "models", "listData": []});

    modelContainer.addMany(collection, "listData", modelCustomer);
    modelContainer.addMany(collection, "listData", modelPets);

    //Map<String, CoreDataEntity> listModel = {"models": modelContainer};

    // storage.setItem('data', listModel["models"]!.value);
    //return dataModelProvider.getItemsCount();
    // } else {
    //   return 0;
    // }
  }

}