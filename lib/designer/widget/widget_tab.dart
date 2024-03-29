import 'package:flutter/material.dart';

class WidgetTab extends StatefulWidget {
  const WidgetTab(
      {required this.listTab,
      required this.listTabCont,
      required this.heightTab,
      this.onController,
      super.key,
      this.autoHeight});

  final List<Widget> listTab;
  final List<Widget> listTabCont;
  final double heightTab;
  final Function? onController;
  final bool? autoHeight;

  @override
  State<WidgetTab> createState() {
    return _WidgetTabState();
  }
}

class _WidgetTabState extends State<WidgetTab>
    with SingleTickerProviderStateMixin {
  _WidgetTabState();

  late TabController controllerTab;

  @override
  void initState() {
    super.initState();
    controllerTab = TabController(
        vsync: this,
        length: widget.listTab.length,
        animationDuration: const Duration(milliseconds: 200));

    if (widget.onController != null) {
      widget.onController?.call(controllerTab);
    }

    if (widget.autoHeight == true) {
      controllerTab.addListener(() {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    controllerTab.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
      double heightTab = widget.heightTab;
      if (widget.autoHeight == true) {
        return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          getTabActionLayout(widget.listTab, heightTab),
          LayoutBuilder(
            builder: (context, constraints) {
              return widget.listTabCont[controllerTab.index];
            },
          ),
        ]);
      } else {
        var heightContent = viewportConstraints.maxHeight - heightTab - 2;

        return Column(children: <Widget>[
          getTabActionLayout(widget.listTab, heightTab),
          Container(
              padding: const EdgeInsets.all(0.0),
              decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).secondaryHeaderColor)),
              height: heightContent,
              child: TabBarView(
                  controller: controllerTab, children: widget.listTabCont))
        ]);
      }
    });
  }

  Widget getTabActionLayout(List<Widget> listTab, double heightTab) {
    return SizedBox(
      height: heightTab,
      child: ColoredBox(
          color: Colors.transparent,
          child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                  color: Theme.of(context).highlightColor,
                  child: TabBar(
                    // indicatorSize: TabBarIndicatorSize.label,
                    controller: controllerTab,
                    indicator: const UnderlineTabIndicator(
                        borderSide:
                            BorderSide(width: 4, color: Colors.deepOrange),
                        insets: EdgeInsets.only(left: 0, right: 0, bottom: 0)),
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelPadding: const EdgeInsets.only(left: 10, right: 10),
                    tabs: listTab,
                  )))),
    );
  }
}
