import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'package:provider/provider.dart';


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
                children: [
                  SizedBox(width: 10,),
                  Column(
                    children: [
                      Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width*0.6,
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
                        width: MediaQuery.of(context).size.width*0.6,
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
                  SizedBox(width: 7,),
                  SizedBox(
                    width: 10,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => {},
                      icon: const Icon(Icons.swap_vert),
                    ),
                  ),
                  SizedBox(width: 15,),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => {},
                      child: const Text('공유 자전거\n모드', textAlign: TextAlign.center ),
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

class ModalContent extends StatefulWidget {
  const ModalContent({super.key});

  @override
  State<ModalContent> createState() => _ModalContentState();
}

class _ModalContentState extends State<ModalContent> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        child: const Text('당신의 순위 보기'),
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50),
                topRight: Radius.circular(50),
              ),
            ),
            builder: (BuildContext context) {
              return Container(
                height: 200,
                color: Colors.white70,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('@@님은 현재 ##km 주행 중!'),
                      SizedBox(height: 20,),
                      ElevatedButton(
                        child: const Text('지도 보기'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );;
  }
}
