import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:xui_flutter/designer/application_manager.dart';

import '../core/data/core_repository.dart';
import '../core/widget/cw_core_bind.dart';
import '../core/widget/cw_core_drag.dart';
import '../core/widget/cw_core_widget.dart';
import '../core/widget/cw_factory.dart';

class DesignerRepository extends CWWidgetMapRepository {
  const DesignerRepository({super.key, required super.ctx, this.bindWidget});
  final CWBindWidget? bindWidget;

  @override
  State<DesignerRepository> createState() => _DesignerProviderState();

  @override
  void initSlot(String path, ModeParseSlot mode) {}
}

class _DesignerProviderState extends State<DesignerRepository>
    with DraggableWidget {
  TreeViewController? _controller;
  late IndexedTreeNode<CWRepository> nodesRemovedIndexedTree;
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
    return TreeView.indexTyped<CWRepository, IndexedTreeNode<CWRepository>>(
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

  Widget getDrag(IndexedTreeNode<CWRepository> node, Widget child) {
    return getDraggable(DragQueryCtx(node.data!.getCoreDataEntity()), child);
  }

  Container getCell(IndexedTreeNode<CWRepository> node) {
    Widget cell;
    if (node.level == 0) {
      cell = const Text('Result');
    } else {
      cell = getDrag(node, Text(node.data!.getQueryName()));
    }

    List<Widget> children2 = [
      Expanded(child: cell),
    ];

    if (node.level != 0) {
      children2.add(getCrudBtn('Create@${node.data!.id}', 'C'));
      children2.add(getCrudBtn('<Read@${node.data!.id}', '<'));
      children2.add(getCrudBtn('Refresh@${node.data!.id}', 'R'));
      children2.add(getCrudBtn('Read>@${node.data!.id}', '>'));
      children2.add(getCrudBtn('Update@${node.data!.id}', 'U'));
      children2.add(getCrudBtn('Delete@${node.data!.id}', 'D'));
    }

    return Container(
        margin: const EdgeInsets.fromLTRB(25, 0, 0, 0),
        constraints: const BoxConstraints(minHeight: 25),
        child: Row(children: children2));
  }

  Widget getCrudBtn(String id, String text) {
    return getDraggable(
        DragRepositoryEventCtx(id),
        InkWell(
            onTap: () {},
            child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).disabledColor)),
                child: Text(text))));
  }

  IndexedTreeNode<CWRepository> getTreeData() {
    var nodesRemovedIndexedTree = IndexedTreeNode<CWRepository>.root();

    var factory = CWApplication.of().loaderDesigner.factory;

    for (CWRepository aNode in factory.mapRepository.values) {
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
