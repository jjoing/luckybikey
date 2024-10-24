import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'package:luckybiky/screens/searchScreen/modal.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  @override
  Widget build(BuildContext context) {
    final Completer<NaverMapController> _mapControllerCompleter = Completer();

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: ListView(
            children: [
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 10,),
                  Column(
                    children: [
                      Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width*0.65,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.white70
                        ),
                        child: TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '출발지 입력',
                            )
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width*0.65,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.white70
                        ),
                        child: TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '도착지 입력',
                            )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 10,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => {},
                      icon: const Icon(Icons.swap_vert),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: IconButton(
                      onPressed: () => {},
                      icon: Image.asset('assets/images/share_bike_logo.jpeg'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                height: MediaQuery.of(context).size.height*0.6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10)
                ),
                child: NaverMap(
                    options: const NaverMapViewOptions(
                      mapType: NMapType.basic,
                      activeLayerGroups: [
                        NLayerGroup.bicycle,
                        NLayerGroup.transit
                      ],
                      contentPadding: EdgeInsets.all(10)// default : [NLayerGroup.building]
                    ),
                    forceGesture: true,
                    onMapReady: (controller) {
                      _mapControllerCompleter.complete(controller);
                    }
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(child: ModalContent())),
      ],
    );
  }
}
