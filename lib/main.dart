import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'profile.dart';
import 'records.dart';
import 'settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final settings = await SharedPreferences.getInstance();

  runApp( MainApp( settings: settings ) );
}

class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
    required this.settings
  });

  final SharedPreferences settings;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int currPage = 1;
  PageController pageController = PageController( initialPage: 1 );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text( "Operation Translate" )
        ),
        body: PageView(
          controller: pageController,
          onPageChanged: ( newPage ) => setState( () => currPage = newPage ),
          children: [
            Profile(),
            Records( settings: widget.settings ),
            Settings( settings: widget.settings )
          ]
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currPage,
          onTap: (newPage) {
            setState( () => currPage = newPage );
            pageController.jumpToPage(currPage);
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon( Icons.person ),
              label: "Profile"
            ),
            BottomNavigationBarItem(
              icon: Icon( Icons.perm_media ),
              label: "Records"
            ),
            BottomNavigationBarItem(
              icon: Icon( Icons.settings ),
              label: "Settings"
            )
          ]
        )
      ),
      theme: ThemeData.light().copyWith(
        appBarTheme: AppBarTheme(
          centerTitle: true
        )
      ),
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(
          centerTitle: true
        )
      )
    );
  }
}
