import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';

class DesignerQuery extends StatefulWidget {
  const DesignerQuery({Key? key}) : super(key: key);

  @override
  State<DesignerQuery> createState() => _DesignerQueryState();
}

class _DesignerQueryState extends State<DesignerQuery> {
  TreeViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return TreeView.indexTyped(
        builder: (context, node) {
          return Container(
              margin: const EdgeInsets.fromLTRB(25, 0, 0, 0),
              constraints: const BoxConstraints(minHeight: 25),
              child: Row(children: [
                Expanded(child: Text("Item ${node.level}-${node.key}"))
              ]));
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Item tapped: ${item.key}"),
              duration: const Duration(milliseconds: 750),
            ),
          );
        });
  }

  final nodesRemovedIndexedTree = IndexedTreeNode.root()
    ..addAll([
      IndexedTreeNode(key: "0A")..add(IndexedTreeNode(key: "0A1A")),
      IndexedTreeNode(key: "0C")
        ..addAll([
          IndexedTreeNode(key: "0C1A"),
          IndexedTreeNode(key: "0C1B"),
          IndexedTreeNode(key: "0C1C")
            ..addAll([
              IndexedTreeNode(key: "0C1C2A")
                ..addAll([
                  IndexedTreeNode(key: "0C1C2A3A"),
                  IndexedTreeNode(key: "0C1C2A3B"),
                  IndexedTreeNode(key: "0C1C2A3C"),
                ]),
            ]),
        ]),
      IndexedTreeNode(key: "0D"),
      IndexedTreeNode(key: "0E"),
    ]);
}
