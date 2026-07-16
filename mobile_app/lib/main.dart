import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe Firebase Initialization: Prevents app crashes during dev testing
  // if google-services.json (Android) or GoogleService-Info.plist (iOS) are not yet supplied.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase configuration warning: $e.');
    debugPrint('Push notifications will be inactive until Firebase services are registered.');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
