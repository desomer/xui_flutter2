import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/application_manager.dart';

import '../core/data/core_provider.dart';
import '../core/widget/cw_core_bind.dart';
import '../core/widget/cw_core_widget.dart';
import 'designer_selector_query.dart';

class DesignerProvider extends CWWidgetMapProvider {
  const DesignerProvider({super.key, required super.ctx, this.bindWidget});
  final CWBindWidget? bindWidget;

  @override
  State<DesignerProvider> createState() => _DesignerProviderState();

  @override
  void initSlot(String path) {}
}

class _DesignerProviderState extends State<DesignerProvider> {
  TreeViewController? _controller;
  late IndexedTreeNode<CWProvider> nodesRemovedIndexedTree;
  // late CWProvider provider;

  @override
  void initState() {
    super.initState();
    // provider = CWProvider.of(widget.ctx)!;
  }

  @override
  Widget build(BuildContext context) {
    nodesRemovedIndexedTree = getTreeData();
    return getTree();
  }

  Widget getTree() {
    return TreeView.indexTyped<CWProvider, IndexedTreeNode<CWProvider>>(
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
          // var app = CWApplication.of();

          // var tableModel = item.data!.getTableModel();
          // String name =
          //     '${item.data!.getQueryName()} (${tableModel.value['name']})';

          // var itemProvider = app.collection.createEntityByJson('DataHeader', {
          //   'name': name,
          //   'type': item.data!.type,
          //   'tableModel': tableModel,
          //   'idProvider': item.data!.id
          // });
          widget.bindWidget?.onSelect(item.data!.getCoreDataEntity());

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

  Widget getDrag(IndexedTreeNode<CWProvider> node, Widget child) {
    return Draggable<DragQueryCtx>(
        dragAnchorStrategy: dragAnchorStrategy,
        onDragStarted: () {
          // GlobalSnackBar.show(context, 'Drag started');
        },
        data: DragQueryCtx(node.data!.getCoreDataEntity()),
        feedback: Container(
            height: 30,
            width: 100,
            color: Colors.grey,
            child: const Center(child: Icon(Icons.abc))),
        child: child);
  }

  Container getCell(IndexedTreeNode<CWProvider> node) {
    Widget cell;
    if (node.level == 0) {
      cell = const Text('Result');
    } else {
      cell = getDrag(node, Text(node.data!.getQueryName()));
    }

    return Container(
        margin: const EdgeInsets.fromLTRB(25, 0, 0, 0),
        constraints: const BoxConstraints(minHeight: 25),
        child: Row(children: [Expanded(child: cell)]));
  }

  IndexedTreeNode<CWProvider> getTreeData() {
    var nodesRemovedIndexedTree = IndexedTreeNode<CWProvider>.root();

    var factory = CWApplication.of().loaderDesigner.factory;

    for (CWProvider aNode in factory.mapProvider.values) {
      nodesRemovedIndexedTree.add(IndexedTreeNode(key: aNode.id, data: aNode));
    }

    return nodesRemovedIndexedTree;
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
