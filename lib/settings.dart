import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({
    super.key,
    required this.settings
  });

  final SharedPreferences settings;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownMenu(
                dropdownMenuEntries: [
                  DropdownMenuEntry(
                    label: "English",
                    value: "english"
                  ),
                  DropdownMenuEntry(
                    label: "Chinese",
                    value: "chinese"
                  )
                ],
                initialSelection: foreignLanguage,
                label: Text( "Foreign language" ),
                onSelected: (value) {
                  setState( () => foreignLanguage = value! );
                  widget.settings.setString( "foreignLanguage", foreignLanguage );
                }
              ),
              DropdownMenu(
                dropdownMenuEntries: [
                  DropdownMenuEntry(
                    label: "English",
                    value: "english"
                  ),
                  DropdownMenuEntry(
                    label: "Chinese",
                    value: "chinese"
                  )
                ],
                initialSelection: nativeLanguage,
                label: Text( "Native language" ),
                onSelected: (value) {
                  setState( () => nativeLanguage = value! );
                  widget.settings.setString( "nativeLanguage", nativeLanguage );
                }
              )
            ]
          )
        ),
        Text( "Speech pitch: $speechPitch", textAlign: TextAlign.center ),
        ListTile(
          title: Slider(
            divisions: 20,
            max: 2.0,
            onChanged: (value) => setState( () => speechPitch = value ),
            onChangeEnd: (value) => widget.settings.setDouble( "speechPitch", value ),
            value: speechPitch
          )
        ),
        Text( "Speech rate: $speechRate", textAlign: TextAlign.center ),
        ListTile(
          title: Slider(
            divisions: 20,
            max: 2.0,
            onChanged: (value) => setState( () => speechRate = value ),
            onChangeEnd: (value) => widget.settings.setDouble( "speechRate", value ),
            value: speechRate
          )
        ),
        Text( "Speech volume: $speechVolume", textAlign: TextAlign.center ),
        ListTile(
          title: Slider(
            divisions: 20,
            max: 2.0,
            onChanged: (value) => setState( () => speechVolume = value ),
            onChangeEnd: (value) => widget.settings.setDouble( "speechVolume", value ),
            value: speechVolume
          )
        ),
        TextButton(
          onPressed: () {},
          child: Text( "Tutorial" )
        )
      ]
    );
  }
}