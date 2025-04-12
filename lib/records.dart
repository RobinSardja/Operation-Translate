import 'dart:async';

import 'package:flutter/material.dart';

import 'package:google_generative_ai/google_generative_ai.dart';

enum Difficulty {
  newRecruit,
  specialAgent,
  superSpy;

  @override
  String toString() {
    switch( this ) {
      case Difficulty.newRecruit:
        return "New Recruit";
      case Difficulty.specialAgent:
        return "Special Agent";
      case Difficulty.superSpy:
        return "Super Spy";
    }
  }
}

class Record {
  final String topic;
  final Difficulty difficulty;

  Record( this.topic, this.difficulty );
}

class Records extends StatefulWidget {
  const Records({super.key});

  @override
  State<Records> createState() => _RecordsState();
}

class _RecordsState extends State<Records> {
  final temp = [
    Record( "Ordering Food", Difficulty.newRecruit ),
    Record( "Weekend Plans", Difficulty.specialAgent ),
    Record( "Meeting Setup", Difficulty.superSpy )
  ];

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
    return ListView.builder(
      itemBuilder: ( context, index ) {
        final curr = temp[index];
        return ListTile(
          leading: Icon( Icons.folder ),
          onTap: () => Navigator.push(
            context, MaterialPageRoute(
              builder: (context) => Decipher(
                difficulty: curr.difficulty, topic: curr.topic
              )
            )
          ),
          title: Text( "New Record: ${curr.topic}" ),
          subtitle: Text( "Difficulty: ${curr.difficulty}" )
        );
      },
      itemCount: temp.length
    );
  }
}

class Decipher extends StatefulWidget {
  const Decipher({
    super.key,
    required this.difficulty,
    required this.topic
  });

  final Difficulty difficulty;
  final String topic;

  @override
  State<Decipher> createState() => _DecipherState();
}

class _DecipherState extends State<Decipher> {
  Duration elapsedTime = Duration.zero;
  bool showTimer = false;
  late Timer timer;

  String formatTime() {
    final minutes = elapsedTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsedTime.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds = ( elapsedTime.inMilliseconds.remainder(1000) / 10 ).toStringAsFixed(0).padLeft(2, '0');

    return "$minutes:$seconds:$milliseconds";
  }

  void startStopwatch() {
    timer = Timer.periodic( Duration( milliseconds: 10 ), (timer) {
      setState( () => elapsedTime += Duration( milliseconds: 10 ) );
    });
  }

  @override
  void initState() {
    super.initState();

    startStopwatch();
  }

  @override
  void dispose() {
    if( timer.isActive ) timer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon( Icons.timer ),
          onPressed: () => showTimer = !showTimer
        ),
        actions: [
          IconButton(
            icon: Icon( Icons.close ),
            onPressed: () => showDialog(
              builder: (context) => AlertDialog(
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text( "Yes" )
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text( "No" )
                  )
                ],
                content: Text( "Are you sure you want to quit?" ),
                title: Text( "Quitting" )
              ),
              context: context
            )
          )
        ],
        automaticallyImplyLeading: false,
        title: Text( showTimer ? formatTime() : "Deciphering Record" )
      ),
      body: Center( child: Text( "Decipher" ) )
    );
  }
}