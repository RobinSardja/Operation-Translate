import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class MCQ {
  final String question;
  final List<String> options;
  final String correctAnswer;

  MCQ(
    this.question,
    this.options,
    this.correctAnswer,
  );
}

class Record {
  final String topic;
  final Difficulty difficulty;

  Record( this.topic, this.difficulty );
}

class Records extends StatefulWidget {
  const Records({
    super.key,
    required this.settings
  });

  final SharedPreferences settings;

  @override
  State<Records> createState() => _RecordsState();
}

class _RecordsState extends State<Records> {
  final temp = [
    Record( "Ordering Food", Difficulty.newRecruit ),
    Record( "Weekend Plans", Difficulty.specialAgent ),
    Record( "Meeting Setup", Difficulty.superSpy )
  ];

  late String foreignLanguage;
  late String nativeLanguage;

  @override
  void initState() {
    super.initState();

    foreignLanguage = widget.settings.getString( "foreignLanguage" ) ?? "chinese";
    nativeLanguage = widget.settings.getString( "nativeLanguage" ) ?? "english";
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
                difficulty: curr.difficulty,
                foreignLanguage: foreignLanguage,
                nativeLanguage: nativeLanguage,
                topic: curr.topic
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
    required this.foreignLanguage,
    required this.nativeLanguage,
    required this.topic
  });

  final Difficulty difficulty;
  final String foreignLanguage;
  final String nativeLanguage;
  final String topic;

  @override
  State<Decipher> createState() => _DecipherState();
}

class _DecipherState extends State<Decipher> {
  static const apiKey = String.fromEnvironment( "gemini", defaultValue: "none" );
  List<String> convo = [];
  int currSentence = -1;
  Duration elapsedTime = Duration.zero;
  bool isGenerating = true;
  bool isSpeaking = false;
  List<MCQ> questions = [];
  bool showTimer = false;
  late Timer timer;
  final tts = FlutterTts();

  String formatTime() {
    final minutes = elapsedTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsedTime.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds = ( elapsedTime.inMilliseconds.remainder(1000) / 10 ).toStringAsFixed(0).padLeft(2, '0');

    return "$minutes:$seconds:$milliseconds";
  }

  void getConvoAndQuestions() async {
    final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey
    );

    String prompt =
"""
Create a conversation between Bea and Jay about ${widget.topic}.
Start off with societally expected formalities.
Use basic conversational language.
Display each sentence in ${widget.foreignLanguage} in square brackets like so:
Jay: [${widget.foreignLanguage} sentence]
Bea: [${widget.foreignLanguage} sentence]
""";

    String response =( await model.generateContent( [ Content.text( prompt ) ] ) ).text!;

    List<String> lines = response.split('\n');
    RegExp re = RegExp( r'\[(.*?)\]' );

    for( String line in lines ) {
      if( line.startsWith( "Bea: " ) || line.startsWith( "Jay: " ) ) {
        final matches = re.allMatches(line);
        for( Match match in matches ) {
          convo.add( match.group(1)! );
        }
      }
    }

    prompt = """
$response

Create 5 multiple choice questions about the conversation above in ${widget.nativeLanguage}.
Ensure all content below is written in ${widget.nativeLanguage}.
Format each question with the question in square brackets, each of the 4 answer choice in angle brackets, and the correct choice in curly braces, like so:
[Question]
<Answer choice>
<Answer choice>
<Answer choice>
<Answer choice>
{Correct choice}

[Question]
<Answer choice>
<Answer choice>
<Answer choice>
<Answer choice>
{Correct choice}
""";

    response =( await model.generateContent( [ Content.text( prompt ) ] ) ).text!;
    List<String> parts = response.split('\n\n');

    for( String part in parts ) {
      lines = part.split('\n');
      String questionText = lines[0].substring(1, lines[0].length - 1);

      List<String> options = [];
      String correctAnswer = "";

      for( int i = 1; i < lines.length; i++ ) {
        if( lines[i].startsWith('<') && lines[i].endsWith('>') ) {
          options.add( lines[i].substring( 1, lines[i].length - 1 ) );
        } else if( lines[i].startsWith('{') && lines[i].endsWith('}') ) {
          correctAnswer = lines[i].substring( 1, lines[i].length - 1 );
        }
      }

      questions.add( MCQ( questionText, options, correctAnswer ) );
    }

    isGenerating = false;
  }

  void speakSentence( int i ) async {    
    currSentence = i;

    final voices = await tts.getVoices;

    await tts.setVoice( Map<String, String>.from( voices[ currSentence % 2 == 0 ? 4 : 5 ] ) );
    await tts.awaitSpeakCompletion(true);
    await tts.speak( convo[currSentence] );

    currSentence = -1;
  }

  void startStopwatch() {
    timer = Timer.periodic( Duration( milliseconds: 10 ), (timer) {
      setState( () => elapsedTime += Duration( milliseconds: 10 ) );
    });
  }

  @override
  void initState() {
    super.initState();

    tts.setStartHandler( () => setState( () => isSpeaking = true ) );
    tts.setCompletionHandler( () => setState( () => isSpeaking = false ) );

    getConvoAndQuestions();
    startStopwatch();
  }

  @override
  void dispose() async {
    super.dispose();

    timer.cancel();
    if( isSpeaking ) await tts.stop();
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
      body: isGenerating ? Center(
        child: CircularProgressIndicator.adaptive()
      ) : ListView(
        children: convo.asMap().entries.map(
          (entry) => ListTile(
            onTap: () => isSpeaking ?
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text( "Please wait until speaking ends" ),
                action: SnackBarAction( label: "OK", onPressed: () {} ),
                behavior: SnackBarBehavior.floating,
              )
            )
            : speakSentence( entry.key ),
            selected: entry.key == currSentence,
            title: Text( entry.value, textAlign: TextAlign.center )
          )
        ).toList()
      )
    );
  }
}