import 'package:flutter/material.dart';
import 'components/header.dart';
import 'sections/body.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: Header(),
        body: const Body(),
      ),
    );
  }
}
