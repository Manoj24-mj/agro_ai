import 'package:flutter/material.dart';
import 'screens/intro_animation_screen.dart';

void main() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              details.exceptionAsString() + '\n\n' + details.stack.toString(),
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agro AI Doctor',
      home: const IntroAnimationScreen(),
    );
  }
}