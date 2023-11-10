import 'dart:math';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CWFutureWidget extends StatelessWidget {
  const CWFutureWidget({
    required this.getContent,
    required this.futureData,
    required this.nbCol,
    super.key,
  });

  final Function getContent;
  final Future futureData;
  final int nbCol;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureData,
      builder: (
        BuildContext context,
        AsyncSnapshot snapshot,
      ) {
        //debugPrint(snapshot.connectionState.toString());
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Skeletonizer(
            enabled: true,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: 10,
              itemBuilder: (context, index) {
                return Row(
                    children: List.filled(nbCol, 0).map((e) {
                  return Flexible(
                      fit: FlexFit.tight,
                      flex: 1,
                      child: Text(
                          List.filled(Random().nextInt(20), '*').toString(),
                          overflow: TextOverflow.ellipsis));
                }).toList());
              },
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Text('Error');
          } else if (snapshot.hasData) {
            return getContent(snapshot.data);
          } else {
            return const Text('Empty data');
          }
        } else {
          return Text('State: ${snapshot.connectionState}');
        }
      },
    );
  }
}
