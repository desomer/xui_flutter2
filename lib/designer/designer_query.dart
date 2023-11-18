import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:xui_flutter/db_icon_icons.dart';

import '../core/data/core_data.dart';
import '../core/data/core_data_filter.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_future.dart';
import '../core/widget/cw_core_widget.dart';
import 'application_manager.dart';

class DesignerQuery extends CWWidgetMap {
  const DesignerQuery({super.key, required super.ctx});

  @override
  State<DesignerQuery> createState() => _DesignerQueryState();

  @override
  void initSlot(String path) {}
}

final log = Logger('DesignerQuery');

class _DesignerQueryState extends State<DesignerQuery> {
  TreeViewController? _controller;
  late IndexedTreeNode<CoreDataEntity> nodesRemovedIndexedTree;
  late CWProvider provider;

  @override
  void initState() {
    super.initState();
    provider = CWProvider.of(widget.ctx)!;
  }

  @override
  Widget build(BuildContext context) {
    var futureData = widget.initFutureDataOrNot(provider, widget.ctx);

    Widget getContent(int ok) {
      var provider = CWProvider.of(widget.ctx);
      widget.setProviderDataOK(provider, ok);
      nodesRemovedIndexedTree = getTreeData();
      return getTree();
    }

    if (futureData is Future) {
      return CWFutureWidget(
        futureData: futureData,
        getContent: getContent,
        nbCol: 1,
      );
    } else {
      return getContent(futureData as int);
    }
  }

  Widget getTree() {
    return TreeView.indexTyped<CoreDataEntity, IndexedTreeNode<CoreDataEntity>>(
        builder: (context, node) {
          return getCell(node);
        },
        expansionIndicatorBuilder: (context, node) =>
            ChevronIndicator.rightDown(
              alignment: Alignment.topLeft,
              tree: node,
              padding: const EdgeInsets.all(0),
            ),
        tree: nodesRemovedIndexedTree,
        showRootNode: true,
        indentation: const Indentation(style: IndentStyle.squareJoint),
        expansionBehavior: ExpansionBehavior.scrollToLastChild,
        onTreeReady: (controller) {
          _controller = controller;
          _controller!.expandAllChildren(nodesRemovedIndexedTree);
        },
        onItemTap: (item) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text("Item tapped: ${item.key}"),
          //     duration: const Duration(milliseconds: 750),
          //   ),
          // );
        });
  }

  Offset dragAnchorStrategy(
      Draggable<Object> d, BuildContext context, Offset point) {
    return Offset(d.feedbackOffset.dx + 25, d.feedbackOffset.dy - 5);
  }

  Widget getDrag(IndexedTreeNode<CoreDataEntity> node, Widget child) {
    return Draggable<DragQueryCtx>(
        dragAnchorStrategy: dragAnchorStrategy,
        onDragStarted: () {
          // GlobalSnackBar.show(context, 'Drag started');
        },
        data: DragQueryCtx(node.data!),
        feedback: Container(
            height: 30,
            width: 100,
            color: Colors.grey,
            child: const Center(child: Icon(Icons.abc))),
        child: child);
  }

  Container getCell(IndexedTreeNode<CoreDataEntity> node) {
    Widget? cell;
    if (node.level == 0) {
      cell = const Text('Queries');
    } else {
      switch (node.data?.value[r'$type']) {
        case 'DataModel':
          cell = getDrag(node, Row(  children : [const  Icon(DBIcon.database, size: 15), const SizedBox(width: 10), Text("all ${node.data?.value["name"]}")]));
          break;
        case 'DataFilter':
          cell = getDrag(node,  Row( children : [const Icon(Icons.filter_alt_outlined, size: 20), const SizedBox(width: 10), Text("filter ${node.data?.value["name"]}")]));
          break;          
        default:
      }
    }

    return Container(
        margin: const EdgeInsets.fromLTRB(25, 0, 0, 0),
        constraints: const BoxConstraints(minHeight: 25),
        child: Row(children: [Expanded(child: cell!)]));
  }

  IndexedTreeNode<CoreDataEntity> getTreeData() {
    var nodesIndexedTree = IndexedTreeNode<CoreDataEntity>.root();

    var filters = CWApplication.of().mapFilters;
    var mapModelFilter = <String, List<CoreDataFilter>>{};
    for (var element in filters.entries) {
      var value = element.value.dataFilter.value;
      if (mapModelFilter[value['model']] == null) {
        mapModelFilter[value['model']] = [];
      }
      mapModelFilter[value['model']]!.add(element.value);
    }

    for (CoreDataEntity aNode in provider.content) {
      var indexedTreeNode =
          IndexedTreeNode(key: aNode.value['_id_'], data: aNode);

      //log.finest(aNode.value);

      if (mapModelFilter[aNode.value['_id_']] != null) {
        var filtersOfModel = mapModelFilter[aNode.value['_id_']]!;
        for (var element in filtersOfModel) {
          var filterNode = IndexedTreeNode(
              key: element.dataFilter.value['_id_'], data: element.dataFilter);
          indexedTreeNode.add(filterNode);
          //log.finest(element.dataFilter);
        }
      }

      nodesIndexedTree.add(indexedTreeNode);
    }

    return nodesIndexedTree;
  }

  // final nodesRemovedIndexedTree = IndexedTreeNode.root()
  //   ..addAll([
  //     IndexedTreeNode(key: "0A")..add(IndexedTreeNode(key: "0A1A")),
  //     IndexedTreeNode(key: "0C")
  //       ..addAll([
  //         IndexedTreeNode(key: "0C1A"),
  //         IndexedTreeNode(key: "0C1B"),
  //         IndexedTreeNode(key: "0C1C")
  //           ..addAll([
  //             IndexedTreeNode(key: "0C1C2A")
  //               ..addAll([
  //                 IndexedTreeNode(key: "0C1C2A3A"),
  //                 IndexedTreeNode(key: "0C1C2A3B"),
  //                 IndexedTreeNode(key: "0C1C2A3C"),
  //               ]),
  //           ]),
  //       ]),
  //     IndexedTreeNode(key: "0D"),
  //     IndexedTreeNode(key: "0E"),
  //   ]);
}

class DragQueryCtx {
  DragQueryCtx(this.query);
  CoreDataEntity query;
}
