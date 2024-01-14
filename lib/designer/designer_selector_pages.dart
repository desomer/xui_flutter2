import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

import '../core/data/core_data.dart';
import '../core/data/core_provider.dart';
import '../core/widget/cw_core_future.dart';
import '../core/widget/cw_core_widget.dart';
import 'application_manager.dart';

class DesignerPages extends CWWidgetMapProvider {
  const DesignerPages({super.key, required super.ctx});

  @override
  State<DesignerPages> createState() => _DesignerPagesState();

  @override
  void initSlot(String path) {}
}

class _DesignerPagesState extends State<DesignerPages> {
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
          // setState(() {
          //   item.data?.value['_id_'] = 'i';

          // });
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
    return Draggable<DragPagesCtx>(
        dragAnchorStrategy: dragAnchorStrategy,
        onDragStarted: () {
          // GlobalSnackBar.show(context, 'Drag started');
        },
        data: DragPagesCtx(node.data!),
        feedback: Container(
            height: 30,
            width: 100,
            color: Colors.grey,
            child: const Center(child: Icon(Icons.pages))),
        child: child);
  }

  Container getCell(IndexedTreeNode<CoreDataEntity> node) {
    Widget cell;
    if (node.level == 0) {
      cell = const Text('Pages');
    } else {
      if (node.data?.value['_id_'] == 'add') {
        cell = Row(children: [
          Container(
              width: 50,
              margin: const EdgeInsets.all(4),
              child: InkWell(
                  onTap: () {
                    setState(() {
                      var app = CWApplication.of();
                      var createEntityByJson = app.collection
                          .createEntityByJson('PageModel', {'name': 'NewPage'});
                      (node.data?.value['on'] as CoreDataEntity).addMany(
                          app.loaderDesigner, 'subPages', createEntityByJson);
                      //app.pagesProvider.addContent(createEntityByJson);
                    });

                    // CoreDesigner.ofLoader().addWidget('root',
                    //     'page_${provider.id}', 'CWPage', <String, dynamic>{
                    //   'type': provider.type,
                    // });
                  },
                  child: DottedBorder(
                      color: Colors.grey,
                      dashPattern: const <double>[4, 4],
                      strokeWidth: 2,
                      child: const Center(
                          child: Text(
                        '+',
                        style: TextStyle(color: Colors.grey),
                      )))))
        ]);
      } else {
        cell = getDrag(node, Text('${node.data?.value['name']}'));
      }
    }

    return Container(
        margin: const EdgeInsets.fromLTRB(25, 0, 0, 0),
        constraints: const BoxConstraints(minHeight: 25),
        child: Row(children: [Expanded(child: cell)]));
  }

  IndexedTreeNode<CoreDataEntity> getTreeData() {
    var nodesRemovedIndexedTree = IndexedTreeNode<CoreDataEntity>.root();

    for (CoreDataEntity aNode in provider.content) {
      IndexedTreeNode<CoreDataEntity> indexedTreeNode = getTreePage(aNode);
      nodesRemovedIndexedTree.add(indexedTreeNode);
    }

    return nodesRemovedIndexedTree;
  }

  IndexedTreeNode<CoreDataEntity> getTreePage(CoreDataEntity aNode) {
    var indexedTreeNode =
        IndexedTreeNode(key: aNode.value['_id_'], data: aNode);

    var listSubPage =
        aNode.getManyEntity(CWApplication.of().collection, 'subPages') ?? [];

    for (var aSubPage in listSubPage) {
      indexedTreeNode.add(getTreePage(aSubPage));
    }

    addNodeNewPage(indexedTreeNode, aNode);
    return indexedTreeNode;
  }

  void addNodeNewPage(
      IndexedTreeNode<CoreDataEntity> indexedTreeNode, CoreDataEntity aNode) {
    CoreDataEntity ent = CWApplication.of().collection.createEntityByJson(
        'PageModel', {'_id_': 'add', 'name': 'add', 'on': aNode});

    indexedTreeNode.add(IndexedTreeNode(key: aNode.value['_id_']+'#add', data: ent));
  }
}

class DragPagesCtx {
  DragPagesCtx(this.query);
  CoreDataEntity query;
}
