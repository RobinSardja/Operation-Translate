import 'package:flutter/material.dart';

import 'package:google_generative_ai/google_generative_ai.dart';

class Records extends StatefulWidget {
  const Records({super.key});

  @override
  State<Records> createState() => _RecordsState();
}

class _RecordsState extends State<Records> {
  static const apiKey = String.fromEnvironment( "gemini", defaultValue: "none" );
  String output = "Click the button above to generate!";

  Future<String> pipe( String prompt ) async {
    final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey
    );

    final content = [ Content.text(prompt) ];
    final response = await model.generateContent(content);

    return response.text ?? "ERROR";
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: FloatingActionButton(
            onPressed: () async {
              output = await pipe( "Hello! How are you?" );
              setState(() {});
            }
          )
        ),
        ListTile(
          title: Text( output )
        )
      ]
    );
  }
}