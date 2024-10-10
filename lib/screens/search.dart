import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';


class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  @override
  Widget build(BuildContext context) {
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  return Scaffold(
    appBar: AppBar(
        title: const Text("Naver Map Example"),
      ),
    body: NaverMap(
      options: const NaverMapViewOptions(),
      onMapReady: (controller) {
        _mapControllerCompleter.complete(controller);
        print("NaverMap Loading complete!");
      },
    ),
  );
  }
}
