import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  const Profile({
    super.key,
    required this.settings
  });

  final SharedPreferences settings;

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late int questionsAttempted;
  late int questionsCorrect;

  @override
  void initState() {
    super.initState();

    questionsAttempted = widget.settings.getInt( "questionsAttempted" ) ?? 0;
    questionsCorrect = widget.settings.getInt( "questionsCorrect" ) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text( "Welcome back, Agent Sardja", textAlign: TextAlign.center )
        ),
        Image.asset( "assets/negative.png" ),
        ListTile(
          title: Text( "Total questions attempted: $questionsAttempted", textAlign: TextAlign.center )
        ),
        ListTile(
          title: Text( "Total questions correct: $questionsCorrect", textAlign: TextAlign.center )
        ),
        ListTile(
          title: Text( "Average case accuracy: ${ questionsAttempted == 0 ? 0 : ( ( questionsCorrect / questionsAttempted ) * 100 ).round() }%", textAlign: TextAlign.center )
        )
      ]
    );
  }
}