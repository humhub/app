import 'package:flutter/material.dart';
import '../Pages/Opener.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xff21A1B3),
      ),
      home: Opener(),
    );
  }
}
