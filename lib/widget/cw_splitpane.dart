import 'package:flutter/material.dart';

class SplitPane extends StatefulWidget {

  const SplitPane({super.key, required this.child1, required this.child2, this.tapSize = 20, this.dividerSize = 5});
      
  final Widget child1;
  final Widget child2;
  final double tapSize;
  final double dividerSize;

  @override
  State<SplitPane> createState() => _SplitPaneState();
}

class _SplitPaneState extends State<SplitPane> {
  Offset? dividerOffset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext ctx, BoxConstraints c) {
          dividerOffset ??= Offset(c.biggest.width / 2, 0);
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(width: dividerOffset!.dx, child: widget.child1),
                  Container(
                    width: widget.dividerSize,
                    color: Colors.grey,
                  ),
                  SizedBox(
                    width: c.biggest.width - widget.dividerSize - dividerOffset!.dx,
                    child: widget.child2
                  ),
                ],
              ),
              Positioned(
                left: dividerOffset!.dx - ((widget.tapSize) / 2) + (widget.dividerSize/2),
                top: dividerOffset!.dy,
                child: GestureDetector(
                  onPanUpdate: (d) {
                    final Offset newOffset = Offset(dividerOffset!.dx + d.delta.dx, dividerOffset!.dy);
                    if (c.biggest.width * 0.1 < newOffset.dx &&
                        c.biggest.width * 0.9 > newOffset.dx) {
                      setState(() {
                        dividerOffset = newOffset;
                      });
                    }
                  },
                  child: Container(
                    width: widget.tapSize,
                    height: c.biggest.height,
                    color: Colors.transparent,
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
