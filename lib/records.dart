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
  final List<String> choices;
  final String correct;

  MCQ( this.question, this.choices, this.correct );
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
  late double speechPitch;
  late double speechRate;
  late double speechVolume;

  @override
  void initState() {
    super.initState();

    foreignLanguage = widget.settings.getString( "foreignLanguage" ) ?? "chinese";
    nativeLanguage = widget.settings.getString( "nativeLanguage" ) ?? "english";
    speechPitch = widget.settings.getDouble( "speechPitch" ) ?? 1.0;
    speechRate = widget.settings.getDouble( "speechRate" ) ?? 0.5;
    speechVolume = widget.settings.getDouble( "speechVolume" ) ?? 1.0;
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
                settings: widget.settings,
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
    required this.settings,
    required this.topic
  });

  final Difficulty difficulty;
  final SharedPreferences settings;
  final String topic;

  @override
  State<Decipher> createState() => _DecipherState();
}

class _DecipherState extends State<Decipher> {
  static const apiKey = String.fromEnvironment( "gemini", defaultValue: "none" );
  List<String> convo = [];
  int currSentence = -1;
  Duration elapsedTime = Duration.zero;
  late String foreignLanguage;
  bool isGenerating = true;
  bool isSpeaking = false;
  late String nativeLanguage;
  List<MCQ> questions = [];
  late int questionsAttempted;
  late int questionsCorrect;
  List<String?> selectedAnswers = [null, null, null, null, null];
  bool showTimer = false;
  late double speechPitch;
  late double speechRate;
  late double speechVolume;
  late Timer timer;
  final tts = FlutterTts();

  String formatTime() {
    final minutes = elapsedTime.inMinutes.remainder(60).toString().padLeft( 2, '0' );
    final seconds = elapsedTime.inSeconds.remainder(60).toString().padLeft( 2, '0' );
    final milliseconds = ( elapsedTime.inMilliseconds.remainder(1000) / 10 ).toStringAsFixed(0).padLeft( 2, '0' );

    return "$minutes:$seconds.$milliseconds";
  }

  void getConvoAndQuestions() async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey
      );

      String prompt =
"""
Create a conversation between Bea and Jay about ${widget.topic}.
Start off with societally expected formalities.
Use basic conversational language.
Display each sentence in $foreignLanguage in square brackets like so:
Jay: [$foreignLanguage sentence]
Bea: [$foreignLanguage sentence]
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

Create 5 multiple choice questions about the conversation above in $nativeLanguage.
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

      response = ( await model.generateContent( [ Content.text( prompt ) ] ) ).text!;
      List<String> parts = response.split('\n\n');

      for( String part in parts ) {
        lines = part.split('\n');
        String questionText = lines[0].substring( 1, lines[0].length - 1 );

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
    } catch(e) {
      getConvoAndQuestions();
    }
  }

  void speakSentence( int i ) async {    
    currSentence = i;

    final voices = await tts.getVoices;

    await tts.setPitch( speechPitch );
    await tts.setSpeechRate( speechRate );
    await tts.setVolume( speechVolume );

    await tts.setVoice( Map<String, String>.from( voices[ currSentence % 2 == 0 ? 4 : 5 ] ) );
    await tts.awaitSpeakCompletion( true );
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

    foreignLanguage = widget.settings.getString( "foreignLanguage" ) ?? "chinese";
    nativeLanguage = widget.settings.getString( "nativeLanguage" ) ?? "english";
    questionsAttempted = widget.settings.getInt( "questionsAttempted" ) ?? 0;
    questionsCorrect = widget.settings.getInt( "questionsCorrect" ) ?? 0;
    speechPitch = widget.settings.getDouble( "speechPitch" ) ?? 1.0;
    speechRate = widget.settings.getDouble( "speechRate" ) ?? 0.5;
    speechVolume = widget.settings.getDouble( "speechVolume" ) ?? 1.0;

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
            icon: Icon( Icons.check ),
            onPressed: () => showDialog(
              builder: (context) => AlertDialog(
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      Navigator.pop(context);

                      int score = 0;
                      for( int i = 0; i < 5; i++ ) {
                        if( selectedAnswers[i] == questions[i].correct ) {
                          score++;
                        }
                      }

                      widget.settings.setInt( "questionsCorrect", questionsCorrect + score );
                      widget.settings.setInt( "questionsAttempted", questionsAttempted + 5 );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text( "You got $score/5 correct in ${formatTime()}!" ),
                          action: SnackBarAction( label: "OK", onPressed: () {} ),
                          behavior: SnackBarBehavior.floating
                        )
                      );
                    },
                    child: Text( "Yes" )
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text( "No" )
                  )
                ],
                content: Text( "Are you ready to submit?" ),
                title: Text( "Submitting" )
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
      ) : Column(
        children: [
          Expanded(
            flex: 1,
            child: ListView(
              children: convo.asMap().entries.map(
                (entry) => ListTile(
                  leading: Icon( entry.key % 2 == 0 ? Icons.male : Icons.female ),
                  onTap: () => isSpeaking ?
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text( "Please wait until speaking ends" ),
                      action: SnackBarAction( label: "OK", onPressed: () {} ),
                      behavior: SnackBarBehavior.floating
                    )
                  )
                  : speakSentence( entry.key ),
                  selected: entry.key == currSentence,
                  title: Text( entry.value, textAlign: TextAlign.center )
                )
              ).toList()
            ),
          ),
          Expanded(
            flex: 1,
            child: PageView(
              children: questions.asMap().entries.map(
                (entry) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text( "(${entry.key + 1}) ${entry.value.question}", textAlign: TextAlign.center ),
                    RadioListTile(
                      groupValue: selectedAnswers[ entry.key ],
                      onChanged: (value) => setState( () => selectedAnswers[ entry.key ] = value ),
                      title: Text( entry.value.choices[0] ),
                      value: entry.value.choices[0]
                    ),
                    RadioListTile(
                      groupValue: selectedAnswers[ entry.key ],
                      onChanged: (value) => setState( () => selectedAnswers[ entry.key ] = value ),
                      title: Text( entry.value.choices[1] ),
                      value: entry.value.choices[1]
                    ),
                    RadioListTile(
                      groupValue: selectedAnswers[ entry.key ],
                      onChanged: (value) => setState( () => selectedAnswers[ entry.key ] = value ),
                      title: Text( entry.value.choices[2] ),
                      value: entry.value.choices[2]
                    ),
                    RadioListTile(
                      groupValue: selectedAnswers[ entry.key ],
                      onChanged: (value) => setState( () => selectedAnswers[ entry.key ] = value ),
                      title: Text( entry.value.choices[3] ),
                      value: entry.value.choices[3]
                    )
                  ]
                )
              ).toList()
            )
          )
        ] 
      )
    );
  }
}