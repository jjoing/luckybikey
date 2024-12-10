import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'navigation_utils.dart';

class Navigation extends StatefulWidget {
  const Navigation({
    Key? key,
    required this.routeInfo,
    required this.tts,
    required this.firestore,
    required this.authentication,
  }) : super(key: key);

  final Map<String, dynamic> routeInfo;
  final FlutterTts tts;
  final FirebaseFirestore firestore;
  final FirebaseAuth authentication;

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  final Key _mapKey = UniqueKey();
  Map<String, dynamic> navState = {};
  NaverMapController? ct;
  Timer? timer;
  bool toggleFeedback = false;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    navState = {
      'Route': widget.routeInfo['route'],
      "Start": widget.routeInfo['route'][0],
      "End": widget.routeInfo['route'][widget.routeInfo['route'].length - 1],
      "CurrentPosition": {
        "latitude": widget.routeInfo['route'][0]["NLatLng"].latitude,
        "longitude": widget.routeInfo['route'][0]["NLatLng"].longitude
      },
      "CurrentIndex": 0,
      "ProjectedPosition": {},
      "Angle": 0,
      "ttsFlag": [false, false, false],
      "finishFlag": false,
      "feedbackCounter": 0,
    };

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      print('timer');

      setState(() {
        navState = updateNavState(navState, ct, widget.tts);
        if (navState['feedbackCounter'] > 0) {
          toggleFeedback = true;
        } else {
          toggleFeedback = false;
        }

        NMarker marker1 = NMarker(
          id: 'test1',
          position: NLatLng(
            navState['ProjectedPosition']['latitude'],
            navState['ProjectedPosition']['longitude'],
          ),
        );
        NMarker marker2 = NMarker(
          id: 'test2',
          position: NLatLng(
            navState['CurrentPosition']['latitude'],
            navState['CurrentPosition']['longitude'],
          ),
        );
        NMarker marker3 = NMarker(
          id: 'test3',
          position: NLatLng(
            navState['Route'][navState['CurrentIndex']]['NLatLng'].latitude,
            navState['Route'][navState['CurrentIndex']]['NLatLng'].longitude,
          ),
        );
        ct?.addOverlayAll({marker1, marker2, marker3});
        ct?.updateCamera(NCameraUpdate.withParams(
          target: NLatLng(
            navState['ProjectedPosition']['latitude'],
            navState['ProjectedPosition']['longitude'],
          ),
          zoom: 17,
          bearing: navState['Angle'],
          tilt: 45,
        ));
      });
      // print("navState['Angle']: ${navState['Angle']}");
      // print("navState['CurrentPosition']: ${navState['CurrentPosition']}");
      // print("navState['CurrentIndex']: ${navState['CurrentIndex']}");

      if (navState['finishFlag']) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return Navigationend(
                  fullDistance: widget.routeInfo['full_distance'],
                  tick: t.tick.toDouble(),
                  firestore: widget.firestore,
                  authentication: widget.authentication);
            });
        timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Completer<NaverMapController> mapControllerCompleter = Completer();
    return Dialog(
      insetPadding: const EdgeInsets.all(0),
      child: Stack(
        children: <Widget>[
          NaverMap(
            key: _mapKey,
            options: NaverMapViewOptions(
              mapType: NMapType.navi,
              initialCameraPosition: NCameraPosition(
                target: widget.routeInfo['route'][0]
                    ['NLatLng'], // NLatLng로 변환된 출발지 좌표
                zoom: 17,
                bearing: calculateBearing(
                  widget.routeInfo['route'][0]['NLatLng'].latitude,
                  widget.routeInfo['route'][0]['NLatLng'].longitude,
                  widget.routeInfo['route'][1]['NLatLng'].latitude,
                  widget.routeInfo['route'][1]['NLatLng'].longitude,
                ),
                tilt: 45,
              ),
              locationButtonEnable: true,
              contentPadding: const EdgeInsets.all(10),
            ),
            forceGesture: true,
            onMapTapped: (point, latLng) {
              setState(() {
                navState['CurrentPosition'] = {
                  'latitude': latLng.latitude,
                  'longitude': latLng.longitude,
                };
              });
            },
            onMapReady: (controller) {
              mapControllerCompleter.complete(controller);
              setState(() {
                ct = controller;
              });
              // ct?.setLocationTrackingMode(NLocationTrackingMode.follow);
              final path1 = NPathOverlay(
                id: 'route',
                coords: List<NLatLng>.from(widget.routeInfo['route']
                    .map((e) => e["NLatLng"])), // NLatLng로 변환된 좌표 리스트
                color: const Color.fromARGB(255, 119, 201, 27),
                width: 5,
              );
              controller.addOverlay(path1);
            },
          ),
          Positioned(
            top: 10,
            right: 10,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ),
          if (toggleFeedback)
            Positioned(
              top: 10, left: 10, child: Text(""), // tapWidget,
            ),
        ],
      ),
    );
  }
}
