import 'package:flutter/material.dart';
import 'home_page.dart';



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
      theme: ThemeData(
        primarySwatch: Colors.lime,
      ),
      home: const MyHomePage(title: 'Bắc Hưng Hải: the game'),
    );
  }
}
