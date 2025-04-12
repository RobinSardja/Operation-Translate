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

  @override
  void initState() {
    super.initState();

    foreignLanguage = widget.settings.getString( "foreignLanguage" ) ?? "chinese";
    nativeLanguage = widget.settings.getString( "nativeLanguage" ) ?? "english";
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
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
        )
      ]
    );
  }
}