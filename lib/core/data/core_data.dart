import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:json_patch/json_patch.dart';
import 'package:nanoid/nanoid.dart';

import '../widget/cw_core_loader.dart';
import 'core_event.dart';

class CoreDataCollection {
  final Map<String, CoreDataObjectBuilder> objects =
      <String, CoreDataObjectBuilder>{};

  CoreDataObjectBuilder addObject(String name) {
    debugPrint('add model $name');
    final CoreDataObjectBuilder ret = CoreDataObjectBuilder(name);
    objects[name] = ret;
    return ret;
  }

  CoreDataObjectBuilder? getClass(String name) {
    return objects[name];
  }

  CoreDataEntity createEntityByJson(String cls, Map<String, dynamic> v) {
    return getClass(cls)!.createEntity().setAllValue(v);
  }

  CoreDataEntity createEntity(String cls) {
    return getClass(cls)!.createEntity();
  }
}
//////////////////////////////////////////////////////////////////////

enum CDActionData { defValue }

///----------------------------------------------------
class CoreDataObjectBuilder {
  CoreDataObjectBuilder(this.name);

  late String name;
  final List<CoreDataAttribut> _attributs = <CoreDataAttribut>[];
  final Map<String, CoreDataAttribut> attributsByName =
      <String, CoreDataAttribut>{};
  final Map<String, CoreDataBrowseAction> actions =
      <String, CoreDataBrowseAction>{};

  final List<CoreDataObjectBuilder> groupAttributs = <CoreDataObjectBuilder>[];

  CoreDataObjectBuilder addGroup(CoreDataObjectBuilder group) {
    groupAttributs.add(group);
    return this;
  }

  List<CoreDataAttribut> getAllAttribut() {
    List<CoreDataAttribut> ret = <CoreDataAttribut>[];
    ret.addAll(_attributs);
    for (var element in groupAttributs) {
      ret.addAll(element.getAllAttribut());
    }
    return ret;
  }

  CoreDataObjectBuilder addObjectAction(String name, Function action) {
    actions[name] = CoreDataActionGetter(action);
    return this;
  }

  CoreDataAttribut addAttribut(String name, CDAttributType type,
      {String? tname}) {
    final CoreDataAttribut ret = CoreDataAttribut(name);
    ret.type = type;
    ret.typeName = tname;
    _attributs.add(ret);
    attributsByName[name] = ret;
    return ret;
  }

  CoreDataAttribut? _lastAttr;
  CoreDataObjectBuilder addAttr(String name, CDAttributType type,
      {String? tname}) {
    _lastAttr = addAttribut(name, type, tname: tname);
    return this;
  }

  CoreDataObjectBuilder addAttrAction(String actionId, Function action) {
    _lastAttr?.addAction(actionId, CoreDataActionGetter(action));
    return this;
  }

  CoreDataObjectBuilder withAction(AttrAction action) {
    _lastAttr?.addAction(action.id, CoreDataActionGetter(action.fct));
    return this;
  }

  CoreDataEntity createEntity() {
    final CoreDataEntity ret = CoreDataEntity(name);

    var allAttribut = getAllAttribut();

    for (final CoreDataAttribut attr in allAttribut) {
      if (attr.actions[CDActionData.defValue.toString()] != null) {
        for (var element in attr.actions[CDActionData.defValue.toString()]!) {
          CoreDataCtx ctx = CoreDataCtx();
          ctx.payload = CoreAttrCtx(ret, attr);
          element.execute(ctx);
        }
      }
    }
    ret._operation = CDAction.none;
    ret.value[r'$type'] = name;

    return ret;
  }

  CoreDataEntity getEntityModel() {
    final CoreDataEntity ret = CoreDataEntity(name);
    return ret;
  }
}

class AttrAction {
  AttrAction(this.id, this.fct);
  String id;
  Function(CoreAttrCtx) fct;
}

class AttrActionDefault extends AttrAction {
  dynamic val;
  AttrActionDefault(this.val)
      : super(CDActionData.defValue.toString(), (CoreAttrCtx event) {
          event.entity.value[event.attr.name] = val;
        });
}

class AttrActionDefaultUUID extends AttrAction {
  AttrActionDefaultUUID()
      : super(CDActionData.defValue.toString(), (CoreAttrCtx event) {
          if (event.entity.value[event.attr.name] == null) {
            event.entity.value[event.attr.name] =
                customAlphabet('1234567890abcdef', 10);
          }
        });
}

///----------------------------------------------------
class CoreDataEntity {
  CoreDataEntity(this.type);

  String type; // type de l'entity
  CDAction _operation = CDAction.inherit;
  Map<String, dynamic> value = <String, dynamic>{};
  Map<String, dynamic>? original;
  List<Iterable<Map<String, dynamic>>>? patch;
  List<Iterable<Map<String, dynamic>>>? patchRedo;
  Map<String, dynamic> custom = <String, dynamic>{};

  CDAction get operation {
    int? v = value['_operation_'];
    if (v != null) {
      _operation = CDAction.values[v];
    }
    return _operation;
  }

  set operation(CDAction v) {
    _operation = v;
    value['_operation_'] = v.index;
  }

  @override
  String toString() {
    return '<$type>$value';
  }

  CoreDataEntity setAllValue(Map<String, dynamic> v) {
    value.addAll(v);
    return this;
  }

  CoreDataEntity setAttr(CWAppLoaderCtx loader, String attrName, dynamic v) {
    final CoreDataAttribut? attr = getAttrByName(loader, attrName);
    if (attr != null) {
      // ignore: avoid_dynamic_calls
      value[attrName] = v;
    }
    patchRedo = null;
    return this;
  }

  CoreDataAttribut? getAttrByName(CWAppLoaderCtx loader, String attrName) {
    final CoreDataObjectBuilder? builder =
        loader.collectionDataModel.getClass(type) ??
            loader.collectionWidget.getClass(type);

    CoreDataAttribut? attr = builder?.attributsByName[attrName];
    if (builder != null && attr == null) {
      for (var group in builder.groupAttributs) {
        attr = group.attributsByName[attrName];
        if (attr != null) return attr;
      }
    }
    return attr;
  }

  CoreDataEntity setOne(
      CWAppLoaderCtx loader, String attrName, CoreDataEntity v) {
    final CoreDataAttribut? attr = getAttrByName(loader, attrName);
    if (attr != null) {
      // ignore: avoid_dynamic_calls
      value[attrName] = v.value;
    }
    patchRedo = null;
    return this;
  }

  CoreDataEntity addMany(
      CWAppLoaderCtx loader, String attrName, CoreDataEntity v) {
    final CoreDataAttribut? attr = getAttrByName(loader, attrName);
    if (attr != null) {
      // ignore: avoid_dynamic_calls
      if (value[attrName] == null) {
        value[attrName] = <dynamic>[];
      }
      (value[attrName] as List<dynamic>).add(v.value);
    }
    patchRedo = null;
    return this;
  }

  CoreDataEntity getOne(
      CoreDataCollection collection, String attrName, String typeName) {
    final CoreDataObjectBuilder builder = collection.getClass(typeName)!;
    final CoreDataEntity val = builder.getEntityModel();
    val.value = value[attrName] as Map<String, dynamic>;
    return val;
  }

  CoreDataEntity? getOneEntity(CoreDataCollection collection, String attrName) {
    if (value[attrName] == null) {
      return null;
    }

    final Map<String, dynamic> v = value[attrName] as Map<String, dynamic>;

    final CoreDataObjectBuilder builder =
        collection.getClass(getType(null, v))!;
    final CoreDataEntity val = builder.getEntityModel();
    val.value = v;
    return val;
  }

  // CoreDataEntity? getManyEntity(CoreDataCollection collection, String attrName) {
  //   if (value[attrName] == null) {
  //     return null;
  //   }

  //   final List<Map<String, dynamic>> v = value[attrName] as List<Map<String, dynamic>>;

  //   final CoreDataObjectBuilder builder =
  //       collection.getClass(getType(null, v))!;
  //   final CoreDataEntity val = builder.getEntityModel();
  //   val.value = v;
  //   return val;
  // }

  String? getString(String attr, {String? def}) {
    final dynamic v = value[attr];
    if (v == null) {
      return def;
    } else {
      return v.toString();
    }
  }

  int getInt(String attr, int def) {
    final dynamic v = value[attr];
    if (v == null) {
      return def;
    } else {
      return v as int;
    }
  }

  bool getBool(String attr, bool def) {
    final dynamic v = value[attr];
    if (v == null) {
      return def;
    } else {
      return v as bool;
    }
  }

  CoreDataEntity doChanged() {
    if (operation == CDAction.none) {
      operation = CDAction.create;
    }
    if (operation == CDAction.read) {
      operation = CDAction.update;
    }
    return this;
  }

  CoreDataEntity prepareChange(CoreDataCollection collection) {
    if (original == null) {
      original = <String, dynamic>{};
      debugPrint('add patch vide');
    } else {
      patch ??= <Iterable<Map<String, dynamic>>>[];
      final List<Map<String, dynamic>> ops = JsonPatch.diff(value, original);
      patch!.add(ops);
      debugPrint('add patch$ops');
      original = <String, dynamic>{};
    }

    patchRedo = null;
    _getCloneByEntity(collection, original!, value);
    return this;
  }

  void doPrintObject(String msg) {
    doTrace('$msg $this diff=${getDiff()} orignal=${original ?? "null"}');
  }

  void doTrace(String str) {
    debugPrint('<<< $str');
  }

  void browse(CoreDataCollection collection, CoreDataCtx ctx) {
    _browse(ctx, collection, null, value, '');
  }

  // ignore: constant_identifier_names
  static const String cstTypeAttr = r'$type';

  String getType(CoreDataAttribut? attr, Map<String, dynamic> src) {
    return src[cstTypeAttr]! as String;
  }

  void _browse(CoreDataCtx ctx, CoreDataCollection collection,
      CoreDataAttribut? att, Map<String, dynamic> src, String action) {
    final CoreDataObjectBuilder builder =
        collection.getClass(getType(att, src))!;

    browserObject(ctx, collection, 'browserObject', builder, att, src);

    var allAttribut = builder.getAllAttribut();
    for (final CoreDataAttribut attr in allAttribut) {
      if (attr.type == CDAttributType.one) {
        if (src[attr.name] != null) {
          ctx.pathData.add(attr);
          // un one
          final Map<String, dynamic> o = src[attr.name] as Map<String, dynamic>;
          // ignore: avoid_dynamic_calls
          if (o[cstTypeAttr] != null) { // si c'est typé
            final String tOne = getType(attr, o);
            final CoreDataObjectBuilder builderOne = collection.getClass(tOne)!;
            final CoreDataEntity child = builderOne.getEntityModel();
            child._browse(ctx, collection, attr, o, '');
          }
          ctx.pathData.removeLast();
        }
      } else if (attr.type == CDAttributType.many) {
        // un many
        if (src[attr.name] != null) {
          final List<dynamic> arr = src[attr.name] as List<dynamic>;
          browseAttr(ctx, collection, builder, attr, src);
          ctx.pathData.add(attr);
          for (var i = 0; i < arr.length; i++) {
            final element = arr[i];
            final idxPath = CoreDataAttributItemIdx('[$i]');
            idxPath.idxInArray = i;
            ctx.pathData.add(idxPath);
            final Map<String, dynamic> o = element as Map<String, dynamic>;
            // print("r =" + o.toString());
            // ignore: avoid_dynamic_calls
            final CoreDataObjectBuilder builderOne =
                collection.getClass(getType(attr, o))!;
            final CoreDataEntity child = builderOne.getEntityModel();
            child._browse(ctx, collection, attr, o, 'Item');
            ctx.pathData.removeLast();
          }
          ctx.pathData.removeLast();
        }
      } else {
        // un attribut
        if (src[attr.name] != null) {
          browseAttr(ctx, collection, builder, attr, src);
        }
      }
    }
    browserObject(
        ctx, collection, 'browserObjectEnd$action', builder, att, src);
  }

  void browserObject(
      CoreDataCtx ctx,
      CoreDataCollection collection,
      String action,
      CoreDataObjectBuilder builder,
      CoreDataAttribut? attr,
      Map<String, dynamic> src) {
    final CoreDataBrowseEvent event = CoreDataBrowseEvent();
    event.action = action;
    event.builder = builder;
    event.entity = this;
    value = src;
    event.attr = attr ?? CoreDataAttribut('root');
    event.src = src;
    event.value = src[event.attr.name];
    ctx.event = event;
    ctx.browseHandler.process(ctx);
  }

  void browseAttr(
      CoreDataCtx ctx,
      CoreDataCollection collection,
      CoreDataObjectBuilder builder,
      CoreDataAttribut attr,
      Map<String, dynamic> src) {
    final CoreDataBrowseEvent event = CoreDataBrowseEvent();
    event.action = 'browserAttr';
    event.builder = builder;
    event.entity = this;
    event.attr = attr;
    event.src = src;
    event.value = src[attr.name];
    ctx.event = event;
    ctx.browseHandler.process(ctx);
  }

  void _getCloneByEntity(CoreDataCollection collection,
      Map<String, dynamic> dest, Map<String, dynamic> src) {
    dest[cstTypeAttr] = src[cstTypeAttr];
    final CoreDataObjectBuilder builder = collection.getClass(type)!;
    var allAttribut = builder.getAllAttribut();
    for (final CoreDataAttribut attr in allAttribut) {
      if (attr.type == CDAttributType.one) {
        // un one
        if (src[attr.name] != null) {
          final CoreDataObjectBuilder builderOne =
              collection.getClass(attr.typeName!)!;
          final CoreDataEntity child = builderOne.getEntityModel();
          dest[attr.name] = <String, dynamic>{};
          // ignore: avoid_dynamic_calls
          dest[attr.name][cstTypeAttr] = src[attr.name][cstTypeAttr];
          child._getCloneByEntity(
              collection,
              dest[attr.name] as Map<String, dynamic>,
              src[attr.name] as Map<String, dynamic>);
        }
      } else if (attr.type == CDAttributType.many) {
        final List<dynamic> arr = src[attr.name] as List<dynamic>;

        // ignore: always_specify_types
        for (final element in arr) {
          final Map<String, dynamic> o = element as Map<String, dynamic>;
          // print("r =" + o.toString());
          // ignore: avoid_dynamic_calls
          final CoreDataObjectBuilder builderOne =
              collection.getClass(getType(attr, o))!;
          final CoreDataEntity child = builderOne.createEntity();
          child._getCloneByEntity(collection, child.value, o);
          if (dest[attr.name] == null) {
            dest[attr.name] = <dynamic>[];
          }
          (dest[attr.name] as List<dynamic>).add(child.value);
        }
      } else {
        // un attribut
        if (src[attr.name] != null) {
          dest[attr.name] = src[attr.name];
        }
      }
    }
  }

  CoreDataEntity undoChange(CoreDataCollection collection) {
    if (original != null) {
      patchRedo ??= <Iterable<Map<String, dynamic>>>[];
      final List<Map<String, dynamic>> ops = JsonPatch.diff(original, value);
      patchRedo!.add(ops);
      value = original!;
      if (patch != null && patch!.isNotEmpty) {
        final Iterable<Map<String, dynamic>> diff = patch!.removeLast();
        try {
          final dynamic patchedJson =
              JsonPatch.apply(original, diff, strict: false);
          doTrace('undoChange $diff');
          original = patchedJson as Map<String, dynamic>;
        } on JsonPatchTestFailedException catch (e) {
          doTrace(e.toString());
        }
      } else {
        original = null;
      }
    }
    return this;
  }

  CoreDataEntity redoChange(CoreDataObjectBuilder builder) {
    original = value;
    if (patchRedo != null && patchRedo!.isNotEmpty) {
      final Iterable<Map<String, dynamic>> diff = patchRedo!.removeLast();
      try {
        final dynamic patchedJson = JsonPatch.apply(value, diff, strict: false);
        doTrace('redoChange $diff');
        value = patchedJson as Map<String, dynamic>;
      } on JsonPatchTestFailedException catch (e) {
        doTrace(e.toString());
      }
    }
    return this;
  }

  CoreDataPath getPath(CoreDataCollection collection, String pathId) {
    final List<String> lattr = pathId.split('.');
    final List<CoreDataEntity> ret = <CoreDataEntity>[];
    final List<CoreDataAttribut> attrs = <CoreDataAttribut>[];
    CoreDataEntity cur = this;

    CoreDataObjectBuilder builderOne = collection.getClass(cur.type)!;

    ret.add(cur);
    dynamic value;
    for (String attr in lattr) {
      int idx = -1;
      if (attr.endsWith(']')) {
        final int i = attr.indexOf('[');
        idx = int.parse(attr.substring(i + 1, attr.length - 1));
        attr = attr.substring(0, i);
      }

      CoreDataAttribut attribut = builderOne.attributsByName[attr]!;
      dynamic v = cur.value[attr];
      if (v is List && idx > -1) {
        if (v.length <= idx) {
          break;
        }
        v = v[idx];
        CoreDataAttributItemIdx attIdx = CoreDataAttributItemIdx('$attr[$idx]');
        attIdx.initWith(attribut);
        attIdx.idxInArray = idx;
        attribut = attIdx;
      }

      attrs.add(attribut);

      if (v is Map<String, dynamic>) {
        builderOne = collection.getClass(getType(null, v))!;

        final CoreDataEntity child = builderOne.createEntity();
        child.value = v;
        ret.add(child);
        cur = child;
      }
      value = v;
    }

    final CoreDataPath r = CoreDataPath(ret);
    r.value = value;
    r.pathId = pathId;
    r.attributs = attrs;
    return r;
  }

  List<Map<String, dynamic>> getDiff() {
    final List<Map<String, dynamic>> ops = JsonPatch.diff(original, value);
    return ops;
  }
}

///----------------------------------------------------

class CoreDataPath {
  CoreDataPath(this.entities);
  List<CoreDataEntity> entities;
  late List<CoreDataAttribut> attributs;
  late String pathId;
  dynamic value;

  CoreDataEntity getLastEntity() {
    return entities.last;
  }

  CoreDataEntity remove() {
    CoreDataEntity entity = entities[entities.length - 2];
    CoreDataAttribut attr = attributs[attributs.length - 1];
    entity.value.remove(attr.name);
    return getLastEntity();
  }
}

class CoreDataAttribut {
  CoreDataAttribut(this.name);

  void initWith(CoreDataAttribut src) {
    type = src.type;
    typeName = src.typeName;
    validators = src.validators;
    actions = src.actions;
  }

  late String name;
  CDAttributType type = CDAttributType.text;
  String? typeName;

  Map<int, List<CoreDataValidator>> validators =
      <int, List<CoreDataValidator>>{};
  Map<String, List<CoreDataBrowseAction>> actions =
      <String, List<CoreDataBrowseAction>>{};

  CoreDataAttribut addAction(String actionId, CoreDataBrowseAction action) {
    actions.putIfAbsent(actionId.toString(), () => <CoreDataBrowseAction>[]);
    actions[actionId]!.add(action);
    return this;
  }

  CoreDataAttribut addValidator(CDPriority priority, CoreDataValidator action) {
    validators.putIfAbsent(priority.index, () => <CoreDataValidator>[]);
    validators[priority.index]!.add(action);
    return this;
  }
}

class CoreDataAttributItemIdx extends CoreDataAttribut {
  CoreDataAttributItemIdx(super.name);
  int idxInArray = 0;
}

class CoreDataAttributTyped extends CoreDataAttribut {
  CoreDataAttributTyped(super.name);
  List<String> types = [];
}

class CoreDataValidator {}

abstract class CoreDataBrowseAction {
  dynamic execute(CoreDataCtx ctx) {}
}

class CoreDataActionGetter extends CoreDataBrowseAction {
  CoreDataActionGetter(this.fct);

  Function fct;

  @override
  dynamic execute(CoreDataCtx ctx) {
    return fct(ctx.payload);
  }
}

class CoreAttrCtx {
  CoreAttrCtx(this.entity, this.attr);

  CoreDataEntity entity;
  CoreDataAttribut attr;
}

class CoreDataCtx {
  ListQueue<CoreDataAttribut> pathData = ListQueue<CoreDataAttribut>();
  late CoreBrowseEventHandler browseHandler;
  CoreDataBrowseEvent? event;

  dynamic payload;

  String getPathData() {
    final StringBuffer buffer = StringBuffer();
    for (final CoreDataAttribut element in pathData) {
      if (buffer.length > 0 && element is! CoreDataAttributItemIdx) {
        buffer.write('.');
      }
      buffer.write(element.name);
    }
    return buffer.toString();
  }

  String getParentPathData() {
    final String id = getPathData();
    String idParent = '';
    if (id.isNotEmpty) {
      final int idx = id.lastIndexOf('.');
      if (idx > 0) {
        idParent = id.substring(0, idx);
      }
    }
    return idParent;
  }
}

enum CDAttributType { text, int, dec, date, bool, one, many, dynamic }

enum CDPriority { min, moy, norm, mid, max }

enum CDAction { inherit, none, create, read, update, delete }

class CoreDataBrowseEvent {
  String action = 'browse';
  late CoreDataObjectBuilder builder;
  late CoreDataEntity entity;
  late CoreDataAttribut attr;
  late Map<String, dynamic> src;
  dynamic value;
  dynamic payload1;
}
