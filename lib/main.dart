import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'package:luckybiky/screens/home.dart';
import 'package:luckybiky/screens/search.dart';
import 'package:luckybiky/screens/profile.dart';



void main() async {
  await _initialize();
  runApp(SplashScreen());
}

Future<void> _initialize() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NaverMapSdk.instance.initialize(
    clientId: '**********',
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
            nextScreen: mainHome(),
            splashTransition: SplashTransition.fadeTransition,
            //pageTransitionType: PageTransitionType.scale,
            backgroundColor: Colors.white));
  }
}

class mainHome extends StatefulWidget {
  @override
  State<mainHome> createState() => _mainHomeState();
}

class _mainHomeState extends State<mainHome> {

  int _selectedIndex = 0;
  List _pages = <Widget>[Home(), Search(), Profile()];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "luckybikey",
            style: TextStyle(
              color: Colors.lightGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0.0,
        ),
        body: SafeArea(
          child: _pages[_selectedIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Colors.lightGreen,
          unselectedItemColor: Colors.lightGreenAccent,
          showSelectedLabels: false,
          showUnselectedLabels: false,

          onTap: _onItemTapped,
          currentIndex: _selectedIndex,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home', backgroundColor: Color(0xff1a1d29)),
            const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index){
    setState((){
      _selectedIndex = index;
    });
  }
}

