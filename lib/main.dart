import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:provider/provider.dart';

import 'utils/mapAPI.dart';
import 'screens/home.dart';
import 'screens/searchScreen/search.dart';
import 'screens/profileScreen/profile.dart';
import 'screens/profileScreen/preference_provider.dart';
import 'login.dart';


void main() async {
  await _initialize();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
      ChangeNotifierProvider(
        create: (context) => PreferenceProvider(),
        child: SplashScreen(),
      ),
  );
}

Future<void> _initialize() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NaverMapSdk.instance.initialize(
      clientId: map_id,
      onAuthFailed: (e) => log("네이버맵 인증오류 : $e", name: "onAuthFailed")
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Clean Code',
        home: AnimatedSplashScreen(
            duration: 3500,
            splash: Image.asset('assets/images/bike.gif'),
            nextScreen: login(),
            splashTransition: SplashTransition.fadeTransition,
            //pageTransitionType: PageTransitionType.scale,
            backgroundColor: Colors.white));
  }
}