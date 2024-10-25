import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'package:luckybiky/contents/way_sample_data.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List<NLatLng> sampleData3Coords = Sample_Data_3.map((point) {
    return NLatLng(point['lat'], point['lon']);
  }).toList();


  @override
  Widget build(BuildContext context) {
    final Completer<NaverMapController> _mapControllerCompleter = Completer();

    return Container(

    );
  }
}
