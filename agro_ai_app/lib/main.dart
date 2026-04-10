import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/intro_animation_screen.dart';
import 'service/market_service.dart';

import 'package:agro_ai_app/localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Localization
    await Lang.init();
    
    // Seed database in the background so it doesn't block startup
    MarketService.seedDatabase().catchError((e) => debugPrint("Seeding error: $e"));
    
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }
  
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
    return ListenableBuilder(
      listenable: Lang(),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: Lang.t('title'),
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.unknown},
          ),
          home: const IntroAnimationScreen(),
        );
      },
    );
  }
}