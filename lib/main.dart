import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const BHHGameClient());
}

class BHHGameClient extends StatelessWidget {


  const BHHGameClient({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waste management simulation',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', ''),
        Locale('vn', ''),
      ],
      theme: ThemeData(
        primarySwatch: Colors.lime,
      ),
      home: const MyHomePage(title: 'Bắc Hưng Hải: the game'),
    );
  }
}
