import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';

class ControlsScreen extends StatelessWidget {
  const ControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Controls'),
      ),
      body: FutureBuilder(
        future: rootBundle.loadString('controls.md'),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Markdown(data: snapshot.data!); // Display the markdown content
          }
          return const Center(child: CircularProgressIndicator()); // Show loading indicator
        },
      ),
    );
  }
}
