import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../screens/searchScreen/modal.dart';
import '../../contents/way_sample_data.dart';
import '../../utils/mapAPI.dart';
import '../../components/bottomNaviBar.dart';
import '../../screens/searchScreen/navigation.dart';

enum TtsState { playing, stopped, paused, continued }

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

Future<List<Map<String, dynamic>>> _pulic_bike() async {
  final results = await http.get(Uri.parse(
      'http://openapi.seoul.go.kr:8088/$public_bike_key/json/bikeList/1/1000/'));
  List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
      jsonDecode(results.body)['rentBikeStatus']["row"].map((item) => {
            "NLatLng": NLatLng(double.parse(item['stationLatitude']),
                double.parse(item['stationLongitude'])),
            "StationName": item['stationName'],
            "ParkingBikeTotCnt": item['parkingBikeTotCnt'],
            "RackTotCnt": item['rackTotCnt'],
            "Shared": item['shared'],
            "StationId": item['stationId'],
          }));
  return result;
}

Future<Map<String, dynamic>> search_route(
    searchResult, usePublicBike, publicBikes) async {
  if (usePublicBike) {
    final results = await _request_route({
      "StartPoint": {
        "lat": searchResult[0]['mapy'],
        "lon": searchResult[0]['mapx']
      },
      "EndPoint": {
        "lat": searchResult[1]['mapy'],
        "lon": searchResult[1]['mapx']
      },
      "UseSharing": true,
      "UserTaste": false,
    });

    return results;
  } else {
    final results = await _request_route({
      "StartPoint": {
        "lat": searchResult[0]['mapy'],
        "lon": searchResult[0]['mapx']
      },
      "EndPoint": {
        "lat": searchResult[1]['mapy'],
        "lon": searchResult[1]['mapx']
      },
      "UseSharing": false,
      "UserTaste": false,
    });

    return results;
  }
}

Future<Map<String, dynamic>> _request_route(req) async {
  final results = await FirebaseFunctions.instance
      .httpsCallable('request_route_debug')
      .call(req);

  List<Map<String, dynamic>> route =
      List<Map<String, dynamic>>.from(results.data['route'].map((point) {
    return {
      "NLatLng": NLatLng(point['lat'], point['lon']),
      "distance": point['distance']
    };
  }));

  List<Map<String, dynamic>> route_info = [];

  for (var i = 0; i < route.length - 2; i++) {
    final Map<String, dynamic> current_node = route[i];
    final Map<String, dynamic> next_node = route[i + 1];
    final Map<String, dynamic> next_next_node = route[i + 2];

    final link1 = [
      next_node["NLatLng"].longitude - current_node["NLatLng"].longitude,
      next_node["NLatLng"].latitude - current_node["NLatLng"].latitude,
      0.0,
    ];
    final link1_norm = sqrt(pow(link1[0], 2) + pow(link1[1], 2));
    final link2 = [
      next_next_node["NLatLng"].longitude - next_node["NLatLng"].longitude,
      next_next_node["NLatLng"].latitude - next_node["NLatLng"].latitude,
      0.0,
    ];
    final link2_norm = sqrt(pow(link2[0], 2) + pow(link2[1], 2));
    final cross_product = [
      link1[1] * link2[2] - link1[2] * link2[1],
      link1[2] * link2[0] - link1[0] * link2[2],
      link1[0] * link2[1] - link1[1] * link2[0],
    ];
    final dot_product =
        link1[0] * link2[0] + link1[1] * link2[1] + link1[2] * link2[2];
    route_info.add({
      "NLatLng": current_node["NLatLng"], // 현재 노드의 좌표
      "distance": next_node['distance'], // 다음 노드까지의 거리
      "isleft": cross_product[2] > 0, // 다음 노드에서 좌회전인지 우회전인지 여부
      "angle": acos(dot_product / (link1_norm * link2_norm)) *
          180 /
          pi, // 다음 노드에서의 회전각도
    });
  }
  route_info.add({
    "NLatLng": route[route.length - 2]["NLatLng"],
    "distance": route[route.length - 1]['distance'],
    "isleft": null,
    "angle": null,
  });
  route_info.add({
    "NLatLng": route[route.length - 1]["NLatLng"],
    "distance": null,
    "isleft": null,
    "angle": null,
  });

  return {"route": route_info, "full_distance": results.data['full_distance']};
}

Future<List<Map<String, dynamic>>> _search_request(req) async {
  String query = req['query'];
  final results = await http.get(
    Uri.parse(
        'https://openapi.naver.com/v1/search/local.json?query=$query&display=100&start=1&sort=random'),
    headers: {
      "X-Naver-Client-Id": client_id,
      "X-Naver-Client-Secret": client_secret,
    },
  );
  List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
      jsonDecode(results.body)['items'].map((item) {
    return {
      "title": item['title'].replaceAll(RegExp(r'<[^>]*>'), ''),
      "link": item['link'],
      "category": item['category'],
      "description": item['description'],
      "telephone": item['telephone'],
      "address": item['address'],
      "roadAddress": item['roadAddress'],
      "NLatLng": NLatLng(
          double.parse(item['mapy']) / 10e6, double.parse(item['mapx']) / 10e6),
      "mapx": double.parse(item['mapx']) / 10e6,
      "mapy": double.parse(item['mapy']) / 10e6,
    };
  }));
  return result;
}

class _SearchState extends State<Search> {
  void _permission() async {
    var requestStatus = await Permission.location.request();
    var status = await Permission.location.status;
    if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  final FlutterTts tts = FlutterTts();

  @override
  void initState() {
    _permission();
    super.initState();
    tts.setLanguage("ko-KR"); //언어설정
    tts.setSpeechRate(0.5); //말하는 속도(0.1~2.0)
    tts.setVolume(0.6); //볼륨(0.0~1.0)
    tts.setPitch(1); //음높이(0.5~2.0)
  }

  List<NLatLng> sampleData2Coords = Sample_Data_2.map((point) {
    return NLatLng(point['lat'], point['lon']);
  }).toList();

  List<Map<String, dynamic>> route = [];
  List<Map<String, dynamic>> searchResult = [{}, {}];
  List<Map<String, dynamic>> searchSuggestions = [];
  List<Map<String, dynamic>> publicBikes = [];
  Set<NMarker> publicMarkers = {};

  Key _mapKey = UniqueKey(); // 지도 리로드를 위한 Key
  bool _showMarker = false; // 마커 표시 여부
  bool _showPath = false; // 경로 표시 여부

  var txt_start = TextEditingController();
  var txt_end = TextEditingController();
  var searchToggle = false;
  var searchIndex = 0;
  var cameraPosition = const NLatLng(37.525313, 126.9226753);
  var cameraZoom = 12.0;

  @override
  Widget build(BuildContext context) {
    final Completer<NaverMapController> mapControllerCompleter = Completer();

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
                                  _showPath = false;
                                },
                                textInputAction: TextInputAction.go,
                                onSubmitted: (value) async {
                                  await _search_request({"query": value}).then(
                                      (result) {
                                    setState(() {
                                      _mapKey = UniqueKey();
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
                                        _mapKey = UniqueKey();
                                        searchResult[0] =
                                            searchSuggestions[index];
                                        cameraPosition =
                                            searchResult[0]['NLatLng'];
                                        cameraZoom = 15.0;
                                        controller.closeView(
                                            searchSuggestions[index]['title']);
                                      });
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
                                  _showPath = false;
                                },
                                textInputAction: TextInputAction.go,
                                onSubmitted: (value) async {
                                  await _search_request({"query": value}).then(
                                      (result) {
                                    setState(() {
                                      _mapKey = UniqueKey();
                                      searchSuggestions = result;
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
                                        _mapKey = UniqueKey();
                                        searchResult[1] =
                                            searchSuggestions[index];
                                        cameraPosition =
                                            searchResult[1]['NLatLng'];
                                        cameraZoom = 15.0;
                                        controller.closeView(
                                            searchSuggestions[index]['title']);
                                      });
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
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Navigation(
                                  route: route,
                                  start: searchResult[0],
                                  end: searchResult[1],
                                );
                              },
                            ),
                            if (searchResult[0].isEmpty ||
                                searchResult[1].isEmpty)
                              {
                                tts.speak("출발지와 도착지를 입력해주세요."),
                              }
                            else if (searchResult[0] == searchResult[1])
                              {
                                tts.speak("출발지와 도착지가 같습니다."),
                              }
                            else if (route.isEmpty)
                              {
                                tts.speak("경로를 찾는 중입니다."),
                              }
                            else
                              {
                                tts.speak("안내를 시작합니다."),
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
                            tts.speak("경로를 찾는 중입니다.");
                            print("speak");
                            if (searchResult[0].isEmpty ||
                                searchResult[1].isEmpty) {
                              print("searchResult is empty");
                              return;
                            }
                            search_route(searchResult, _showMarker, publicBikes)
                                .then((result) {
                              setState(() {
                                print("request_route done");
                                _mapKey = UniqueKey();
                                route = result['route'];
                                _showPath = true;
                              });
                            }, onError: (error, stackTrace) {
                              print(error);
                            });
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
                      onMapTapped: (point, latLng) {
                        setState(() {
                          cameraPosition = latLng;
                        });
                      },
                      onMapReady: (controller) {
                        mapControllerCompleter.complete(controller);
                        controller
                            .updateCamera(NCameraUpdate.withParams(
                          target: cameraPosition,
                          zoom: cameraZoom,
                        ))
                            .then((onValue) {
                          // _showPath 상태에 따라 경로 오버레이 추가
                          if (_showPath) {
                            final path2 = NPathOverlay(
                              id: 'samplePath3',
                              coords: List<NLatLng>.from(route.map(
                                  (e) => e["NLatLng"])), // NLatLng로 변환된 좌표 리스트
                              color: Colors.lightGreen,
                              width: 5,
                            );
                            controller.addOverlay(path2);
                          }
                          // _showMarker 상태에 따라 마커 추가
                          if (_showMarker) {
                            if (publicMarkers.isEmpty) {
                              controller.getContentBounds().then((bounds) {
                                for (var i = 0; i < publicBikes.length; i++) {
                                  if (bounds.containsPoint(
                                      publicBikes[i]['NLatLng'])) {
                                    publicMarkers.add(NMarker(
                                      id: publicBikes[i]['StationId'],
                                      position: publicBikes[i]['NLatLng'],
                                      size: const NSize(15, 15),
                                    ));
                                  }
                                }
                                controller.addOverlayAll(publicMarkers);
                              });
                            } else {
                              controller.addOverlayAll(publicMarkers);
                            }
                          } else {
                            publicMarkers.clear();
                          }

                          for (var i = 0; i < searchResult.length; i++) {
                            if (searchResult[i].isEmpty) {
                              continue;
                            }
                            final marker = NMarker(
                              id: 'testMarker$i',
                              position: searchResult[i]['NLatLng'],
                            );
                            controller.addOverlay(marker);
                          }
                        });
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
                      _pulic_bike().then((result) {
                        setState(() {
                          publicBikes = result;
                          _showMarker = true;
                          _mapKey = UniqueKey();
                        });
                      }, onError: (error) {
                        print(error);
                      });
                    } else {
                      setState(() {
                        _showMarker = !_showMarker;
                        _mapKey = UniqueKey();
                      });
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
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(),
    );
  }
}
