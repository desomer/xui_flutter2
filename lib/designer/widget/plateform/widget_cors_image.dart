import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'widget_hub.dart';

class ImgImpl extends GetWidget {
  @override
  Widget getWidget(String url) {
    return _MyImage(url);
  }
}

class _MyImage extends StatelessWidget {
  const _MyImage(this.imageUrl);

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    var url = Uri.https('upload.wikimedia.org',
        'wikipedia/commons/thumb/4/41/Sunflower_from_Silesia2.jpg/1200px-Sunflower_from_Silesia2.jpg');

    return FutureBuilder(
        future: http.get(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(width: 200, height: 200,);
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return const Text('Error');
            } else if (snapshot.hasData) {
              if (snapshot.data!.statusCode == 200) {
                print('response.bodyBytes ${snapshot.data!.bodyBytes.length}');
              } else {
                print(
                    'Request failed with status: ${snapshot.data!.statusCode}.');
              }
              final imageBytes = snapshot.data!.bodyBytes;
              Widget wi = Image.memory(imageBytes, height: 200);
              return wi;
            } else {
              return const Text('Empty data');
            }
          }
          return const Text('Empty data');
        });

    // var response = await http.get(url);
    // if (response.statusCode == 200) {
    //   print('response.bodyBytes ${response.bodyBytes.length}');
    // } else {
    //   print('Request failed with status: ${response.statusCode}.');
    // }
  }
}
