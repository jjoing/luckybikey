import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'modal.dart';
import 'navigation.dart';
import 'navigation_utils.dart';
import 'route_selector.dart';
import '../../components/bottomNaviBar.dart';
import '../../../utils/providers/route_selector_provider.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final FlutterTts tts = FlutterTts();
  NaverMapController? ct;
  final _firestore = FirebaseFirestore.instance;
  final _authentication = FirebaseAuth.instance;

  List<Map<String, dynamic>> route = [];
  double fullDistance = 0.0;
  List<Map<String, dynamic>> searchResult = [{}, {}];
  List<Map<String, dynamic>> searchSuggestions = [];
  List<Map<String, dynamic>> publicBikes = [];
  Set<NMarker> publicMarkers = {};
  List<Color> colors = [
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  final Key _mapKey = UniqueKey(); // 지도 리로드를 위한 Key
  bool _usePublicBike = false; // 마커 표시 여부
  bool _showRouteSelector = false;

  bool searchToggle = false;
  int searchIndex = 0;
  NLatLng cameraPosition = const NLatLng(37.525313, 126.9226753);
  double cameraZoom = 12.0;

  void _permission() async {
    var requestStatus = await Permission.location.request();
    var status = await Permission.location.status;
    if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  void initState() {
    _permission();
    super.initState();
    tts.setLanguage("ko-KR"); //언어설정
    tts.setSpeechRate(0.5); //말하는 속도(0.1~2.0)
    tts.setVolume(0.6); //볼륨(0.0~1.0)
    tts.setPitch(1); //음높이(0.5~2.0)
  }

  @override
  Widget build(BuildContext context) {
    final Completer<NaverMapController> mapControllerCompleter = Completer();
    final RouteSelectorProvider routeSelectorProvider =
        Provider.of<RouteSelectorProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: ListView(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const SizedBox(
                        width: 5,
                      ),
                      Column(
                        children: [
                          Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.white70,
                            ),
                            child: SearchAnchor(builder: (BuildContext context,
                                SearchController controller) {
                              return TextField(
                                controller: controller,
                                onChanged: (value) {
                                  searchResult[0] = {};
                                },
                                textInputAction: TextInputAction.go,
                                onSubmitted: (value) async {
                                  await searchRequest({"query": value}).then(
                                      (result) {
                                    setState(() {
                                      searchSuggestions = result;
                                      searchToggle = true;
                                    });
                                    controller.openView();
                                  }, onError: (error, stackTrace) {
                                    print(error);
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: '출발지 입력',
                                ),
                              );
                            }, suggestionsBuilder: (BuildContext context,
                                SearchController controller) {
                              return List<ListTile>.generate(
                                searchSuggestions.length,
                                (index) {
                                  return ListTile(
                                    title: Text(
                                        searchSuggestions[index]['title'],
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 16)),
                                    subtitle: Text(
                                      searchSuggestions[index]['address'],
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        searchResult[0] =
                                            searchSuggestions[index];
                                      });
                                      ct?.updateCamera(NCameraUpdate.withParams(
                                        target: searchResult[0]['NLatLng'],
                                        zoom: 15.0,
                                      ));
                                      ct?.addOverlay(NMarker(
                                        id: 'startMarker',
                                        position: searchResult[0]['NLatLng'],
                                      ));
                                      controller.closeView(
                                          searchSuggestions[index]['title']);
                                    },
                                  );
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.white70,
                            ),
                            child: SearchAnchor(builder: (BuildContext context,
                                SearchController controller) {
                              return TextField(
                                controller: controller,
                                onChanged: (value) {
                                  searchResult[1] = {};
                                },
                                textInputAction: TextInputAction.go,
                                onSubmitted: (value) async {
                                  await searchRequest({"query": value}).then(
                                      (result) {
                                    setState(() {
                                      searchSuggestions = result;
                                      searchToggle = true;
                                    });
                                    controller.openView();
                                  }, onError: (error, stackTrace) {
                                    print(error);
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: '도착지 입력',
                                ),
                              );
                            }, suggestionsBuilder: (BuildContext context,
                                SearchController controller) {
                              return List<ListTile>.generate(
                                searchSuggestions.length,
                                (index) {
                                  return ListTile(
                                    title: Text(
                                        searchSuggestions[index]['title'],
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 16)),
                                    subtitle: Text(
                                      searchSuggestions[index]['address'],
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        searchResult[1] =
                                            searchSuggestions[index];
                                      });
                                      ct?.updateCamera(NCameraUpdate.withParams(
                                        target: searchResult[1]['NLatLng'],
                                        zoom: 15.0,
                                      ));
                                      ct?.addOverlay(NMarker(
                                        id: 'endMarker',
                                        position: searchResult[1]['NLatLng'],
                                      ));
                                      controller.closeView(
                                          searchSuggestions[index]['title']);
                                    },
                                  );
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 20,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => {
                            if (routeSelectorProvider.selectedIndex == -1)
                              {
                                tts.speak("경로를 선택해주세요."),
                              }
                            else
                              {
                                tts.speak("안내를 시작합니다."),
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Navigation(
                                      routeInfo: routeSelectorProvider
                                              .resultRoute[
                                          routeSelectorProvider.selectedIndex],
                                      tts: tts,
                                      firestore: _firestore,
                                      authentication: _authentication,
                                    );
                                  },
                                ),
                              }
                          },
                          icon: const Icon(Icons.swap_vert),
                        ),
                      ),
                      SizedBox(
                        width: 20,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            route = [];
                            if (searchResult[0].isEmpty ||
                                searchResult[1].isEmpty) {
                              tts.speak("출발지와 도착지를 입력해주세요.");
                              print("출발지와 도착지를 입력해주세요.");
                            } else {
                              tts.speak("경로를 찾는 중입니다.");
                              print("경로를 찾는 중입니다.");
                              setState(() {
                                routeSelectorProvider.resultRoute = [
                                  {},
                                  {},
                                  {},
                                  {},
                                  {}
                                ];
                                searchRoute(
                                    searchResult,
                                    _usePublicBike,
                                    publicBikes,
                                    _firestore,
                                    _authentication,
                                    routeSelectorProvider);
                                _showRouteSelector = true;
                              });

                              // searchRoute(searchResult, _usePublicBike,
                              //         publicBikes, _firestore, _authentication)
                              //     .then((result) {
                              //   setState(() {
                              //     route = result;
                              //     fullDistance = result[0]['full_distance'];
                              //   });
                              //   for (var i = 0; i < route.length; i++) {
                              //     if (route[i].isEmpty) {
                              //       continue;
                              //     }
                              //     final bikepath = route[i]['route'];
                              //     ct?.addOverlay(NPathOverlay(
                              //       id: 'routePath$i',
                              //       coords: List<NLatLng>.from(bikepath.map(
                              //           (e) => e[
                              //               "NLatLng"])), // NLatLng로 변환된 좌표 리스트
                              //       color: colors[i % colors.length],
                              //       width: 3,
                              //     ));
                              //   }
                              // ct?.updateCamera(NCameraUpdate.fitBounds(
                              //   NLatLngBounds.from(
                              //       route.map((e) => e["NLatLng"])),
                              //   padding: const EdgeInsets.all(50),
                              // ));
                              // ct?.addOverlay(NPathOverlay(
                              //   id: 'routePath',
                              //   coords: List<NLatLng>.from(route.map((e) =>
                              //       e["NLatLng"])), // NLatLng로 변환된 좌표 리스트
                              //   color: Colors.lightGreen,
                              //   width: 5,
                              // ));
                              // }, onError: (error, stackTrace) {
                              //   tts.speak("경로를 찾을 수 없습니다.");
                              //   print(error);
                              // });
                              // searchRoute(searchResult, _usePublicBike,
                              //         publicBikes, _firestore, _authentication)
                              //     .then((result) {
                              //   setState(() {
                              //     route = result['route'];
                              //     fullDistance = result['full_distance'];
                              //   });
                              //   ct?.updateCamera(NCameraUpdate.fitBounds(
                              //     NLatLngBounds.from(
                              //         route.map((e) => e["NLatLng"])),
                              //     padding: const EdgeInsets.all(50),
                              //   ));
                              //   ct?.addOverlay(NPathOverlay(
                              //     id: 'routePath',
                              //     coords: List<NLatLng>.from(route.map((e) =>
                              //         e["NLatLng"])), // NLatLng로 변환된 좌표 리스트
                              //     color: Colors.lightGreen,
                              //     width: 5,
                              //   ));
                              // }, onError: (error, stackTrace) {
                              //   tts.speak("경로를 찾을 수 없습니다.");
                              //   print(error);
                              // });
                            }
                          },
                          icon: const Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: NaverMap(
                      key: _mapKey, // 지도 리로드를 위한 Key
                      options: const NaverMapViewOptions(
                        mapType: NMapType.basic,
                        activeLayerGroups: [
                          NLayerGroup.bicycle,
                        ],
                        locationButtonEnable: true,
                        contentPadding: EdgeInsets.all(10),
                      ),
                      forceGesture: true,
                      onMapReady: (controller) {
                        mapControllerCompleter.complete(controller);
                        ct = controller;
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 200,
              left: 20,
              child: SizedBox(
                width: 50,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (publicBikes.isEmpty) {
                      pulicBike().then((result) {
                        setState(() {
                          publicBikes = result;
                          _usePublicBike = true;
                        });
                      }, onError: (error) {
                        print(error);
                      });
                    } else {
                      setState(() {
                        _usePublicBike = !_usePublicBike;
                      });
                    }
                    if (_usePublicBike) {
                      ct?.getContentBounds().then((bounds) {
                        for (var i = 0; i < publicBikes.length; i++) {
                          if (bounds.containsPoint(publicBikes[i]['NLatLng'])) {
                            publicMarkers.add(NMarker(
                              id: publicBikes[i]['StationId'],
                              position: publicBikes[i]['NLatLng'],
                              size: const NSize(15, 15),
                            ));
                          }
                        }
                        ct?.addOverlayAll(publicMarkers);
                      });
                    } else {
                      ct?.clearOverlays();
                    }
                  },
                  icon: Image.asset('assets/images/share_bike_logo.jpeg'),
                ),
              ),
            ),
            const Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(child: ModalContent()),
            ),
            if (_showRouteSelector)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: RouteSelector(ct: ct),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(),
    );
  }
}
