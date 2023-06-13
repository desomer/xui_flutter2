import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:json_patch/json_patch.dart';

import 'core_event.dart';

class CoreDataCollection {
  Map<String, CoreDataObjectBuilder> objects =
      <String, CoreDataObjectBuilder>{};

  CoreDataObjectBuilder addObject(String name) {
    final CoreDataObjectBuilder ret = CoreDataObjectBuilder(name);
    objects[name] = ret;
    return ret;
  }

  CoreDataObjectBuilder? getClass(String name) {
    return objects[name];
  }

  CoreDataEntity createEntityByJson(String cls, Map<String, dynamic> v) {
    return getClass(cls)!.createEntity().setValue(v);
  }

  CoreDataEntity createEntity(String cls) {
    return getClass(cls)!.createEntity();
  }
}

///----------------------------------------------------
class CoreDataObjectBuilder {
  CoreDataObjectBuilder(this.name);

  late String name;
  List<CoreDataAttribut> attributs = <CoreDataAttribut>[];
  Map<String, CoreDataAttribut> attributsByName = <String, CoreDataAttribut>{};
  Map<String, CoreDataAction> actions = <String, CoreDataAction>{};

  CoreDataObjectBuilder addObjectAction(String name, Function action) {
    actions[name] = CoreDataActionGetter(action);
    return this;
  }

  CoreDataAttribut addAttribut(String name, CDAttributType type,
      {String? tname}) {
    final CoreDataAttribut ret = CoreDataAttribut(name);
    ret.type = type;
    ret.typeName = tname;
    attributs.add(ret);
    attributsByName[name] = ret;
    return ret;
  }

  CoreDataAttribut? _lastAttr;
  CoreDataObjectBuilder addAttr(String name, CDAttributType type,
      {String? tname}) {
    _lastAttr = addAttribut(name, type, tname: tname);
    return this;
  }

  CoreDataObjectBuilder addAttrAction(
      String actionId, Function action) {
    _lastAttr?.addAction(actionId, CoreDataActionGetter(action));
    return this;
  }

  CoreDataEntity createEntity() {
    final CoreDataEntity ret = CoreDataEntity(name);

    // for (final CoreDataAttribut attr in attributs) {
    //   ret.value[attr.name] = '';
    // }

    ret.value[r'$type'] = name;

    return ret;
  }

  CoreDataEntity getEntityModel() {
    final CoreDataEntity ret = CoreDataEntity(name);
    return ret;
  }
}

///----------------------------------------------------
class CoreDataEntity {
  CoreDataEntity(this.type);

  String type;
  CDAction operation = CDAction.inherit;
  Map<String, dynamic> value = <String, dynamic>{};
  Map<String, dynamic>? original;
  List<Iterable<Map<String, dynamic>>>? patch;
  List<Iterable<Map<String, dynamic>>>? patchRedo;

  @override
  String toString() {
    return '<$type>$value';
  }

  CoreDataEntity setValue(Map<String, dynamic> v) {
    value.addAll(v);
    return this;
  }

  CoreDataEntity setAttr(
      CoreDataCollection collection, String attrName, dynamic v) {
    final CoreDataObjectBuilder builder = collection.getClass(type)!;
    final CoreDataAttribut? attr = builder.attributsByName[attrName];
    if (attr != null) {
      // ignore: avoid_dynamic_calls
      value[attrName] = v;
    }
    patchRedo = null;
    return this;
  }

  CoreDataEntity setOne(
      CoreDataCollection collection, String attrName, CoreDataEntity v) {
    final CoreDataObjectBuilder builder = collection.getClass(type)!;
    final CoreDataAttribut? attr = builder.attributsByName[attrName];
    if (attr != null) {
      // ignore: avoid_dynamic_calls
      value[attrName] = v.value;
    }
    patchRedo = null;
    return this;
  }

  CoreDataEntity addMany(
      CoreDataCollection collection, String attrName, CoreDataEntity v) {
    final CoreDataObjectBuilder builder = collection.getClass(type)!;
    final CoreDataAttribut? attr = builder.attributsByName[attrName];
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

  String getString(String attr, String def) {
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

  final String typeAttr = r'$type';

  String getType(CoreDataAttribut? attr, Map<String, dynamic> src) {
    return src[typeAttr]! as String;
  }

  void _browse(CoreDataCtx ctx, CoreDataCollection collection,
      CoreDataAttribut? att, Map<String, dynamic> src, String action) {
    final CoreDataObjectBuilder builder =
        collection.getClass(getType(att, src))!;

    browserObject(ctx, collection, 'browserObject', builder, att, src);

    for (final CoreDataAttribut attr in builder.attributs) {
      if (attr.type == CDAttributType.CDone) {
        if (src[attr.name] != null) {
          ctx.pathData.add(attr);
          // un one
          final Map<String, dynamic> o = src[attr.name] as Map<String, dynamic>;
          // ignore: avoid_dynamic_calls
          final String tOne = getType(attr, o);
          final CoreDataObjectBuilder builderOne = collection.getClass(tOne)!;
          final CoreDataEntity child = builderOne.getEntityModel();
          child._browse(ctx, collection, attr, o, '');
          ctx.pathData.removeLast();
        }
      } else if (attr.type == CDAttributType.CDmany) {
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
    final CoreDataEvent event = CoreDataEvent();
    event.action = action;
    event.builder = builder;
    event.entity = this;
    value = src;
    event.attr = attr ?? CoreDataAttribut('root');
    event.src = src;
    event.value = src[event.attr.name];
    ctx.event = event;
    ctx.eventHandler.process(ctx);
  }

  void browseAttr(
      CoreDataCtx ctx,
      CoreDataCollection collection,
      CoreDataObjectBuilder builder,
      CoreDataAttribut attr,
      Map<String, dynamic> src) {
    final CoreDataEvent event = CoreDataEvent();
    event.action = 'browserAttr';
    event.builder = builder;
    event.entity = this;
    event.attr = attr;
    event.src = src;
    event.value = src[attr.name];
    ctx.event = event;
    ctx.eventHandler.process(ctx);
  }

  void _getCloneByEntity(CoreDataCollection collection,
      Map<String, dynamic> dest, Map<String, dynamic> src) {
    dest[typeAttr] = src[typeAttr];
    final CoreDataObjectBuilder builder = collection.getClass(type)!;
    for (final CoreDataAttribut attr in builder.attributs) {
      if (attr.type == CDAttributType.CDone) {
        // un one
        if (src[attr.name] != null) {
          final CoreDataObjectBuilder builderOne =
              collection.getClass(attr.typeName!)!;
          final CoreDataEntity child = builderOne.getEntityModel();
          dest[attr.name] = <String, dynamic>{};
          // ignore: avoid_dynamic_calls
          dest[attr.name][typeAttr] = src[attr.name][typeAttr];
          child._getCloneByEntity(
              collection,
              dest[attr.name] as Map<String, dynamic>,
              src[attr.name] as Map<String, dynamic>);
        }
      } else if (attr.type == CDAttributType.CDmany) {
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
    CoreDataEntity cur = this;
    ret.add(cur);
    for (String attr in lattr) {
      int idx = 0;
      if (attr.endsWith(']')) {
        final int i = attr.indexOf('[');
        idx = int.parse(attr.substring(i + 1, attr.length - 1));
        attr = attr.substring(0, i);
      }

      dynamic v = cur.value[attr];
      if (v is List) {
        v = v[idx];
      }

      final CoreDataObjectBuilder builderOne =
          collection.getClass(getType(null, v as Map<String, dynamic>))!;

      final CoreDataEntity child = builderOne.createEntity();
      child.value = v;
      ret.add(child);
      cur = child;
    }

    final CoreDataPath r = CoreDataPath(ret);
    r.pathId = pathId;
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
  late String pathId;
}

class CoreDataAttribut {
  CoreDataAttribut(this.name);

  late String name;
  CDAttributType type = CDAttributType.CDtext;
  String? typeName;

  Map<int, List<CoreDataValidator>> validators =
      <int, List<CoreDataValidator>>{};
  Map<String, List<CoreDataAction>> actions = <String, List<CoreDataAction>>{};

  CoreDataAttribut addAction(String actionId, CoreDataAction action) {
    actions.putIfAbsent(actionId.toString(), () => <CoreDataAction>[]);
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

class CoreDataValidator {}

abstract class CoreDataAction {
  dynamic execute(CoreDataCtx ctx) {}
}

class CoreDataActionGetter extends CoreDataAction {
  CoreDataActionGetter(this.fct);

  Function fct;

  @override
  dynamic execute(CoreDataCtx ctx) {
    return fct(ctx.payload);
  }
}

class CoreDataCtx {
  ListQueue<CoreDataAttribut> pathData = ListQueue<CoreDataAttribut>();
  late CoreEventHandler eventHandler;

  CoreDataEvent? event;
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

// ignore: constant_identifier_names
enum CDAttributType { CDtext, CDint, CDdec, CDdate, CDone, CDmany, CDPathIdx }

enum CDPriority { min, moy, norm, mid, max }

enum CDAction { inherit, create, insert, update, delete }

class CoreDataEvent {
  String action = 'browse';
  late CoreDataObjectBuilder builder;
  late CoreDataEntity entity;
  late CoreDataAttribut attr;
  late Map<String, dynamic> src;
  dynamic value;
  dynamic payload1;
}
