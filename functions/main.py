# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

# 완성하고 map_data_api branch로 pull해두기

from typing import Dict, List, Tuple
from firebase_functions import firestore_fn, https_fn
from firebase_admin import initialize_app, firestore
from flask import jsonify
from geopy.distance import Distance
from google.cloud.firestore import *
from typing import Optional
import heapq

def get_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    coords1 = (lat1, lon1)
    coords2 = (lat2, lon2)
    return round(Distance(coords1, coords2).m, 3)

class Node:
    def __init__(self, id: int, geometry: Dict[str, float], connections: Dict[int, Dict[str, float]] = {}, parent = None):
        self.id = id
        self.lat = geometry["lat"]
        self.lon = geometry["lon"]
        self.connections = connections
        self.g = 0
        self.h = 90000
        self.f = 0
        self.parent = parent        

    def add_connection(self, node):
        distance = get_distance(self.lat, self.lon, node.lat, node.lon)
        self.connections[node.id] = {"node": node, "distance": distance}

    def __lt__(self, other):
        return self.f < other.f
        
    def __str__(self):
        return f"Node id={self.id} (lat={self.lat}, lon={self.lon})"

    def __dict__(self):
        connections = {
            id: {
                "lat": v["node"].lat,
                "lon": v["node"].lon,
                "distance": v["distance"],
            }
            for id, v in self.connections.items()
        }
        return {"lat": self.lat, "lon": self.lon, "connections": connections}

def heuristic_Manhattan_distance(cur_node : Node, end_node : Node) -> float:
    mid_location = (cur_node.lat,end_node.lon)
    manhattan_dist = Distance((cur_node.lat, cur_node.lon),mid_location).meters + Distance(mid_location, (end_node.lat, end_node.lon)).meters
    return manhattan_dist

def astar_road_finder(start_node : Node, end_node: Node, use_sharing = False, user_taste = False) -> list :
    #start node부터 end node 찾는 알고리즘
    open_list = []
    closed_set = []
    start_node.h = heuristic_Manhattan_distance(start_node,end_node)
    heapq.heappush(open_list,start_node)

    while (open_list != []):
        cur_node = heapq.heappop(open_list)
        closed_set.append(cur_node)

        if cur_node == end_node :
            final_road = []
            total_distance = cur_node.g
            while(cur_node is not None):
                final_road.append({"node_id": cur_node.id, "lat": cur_node.lat, "lon": cur_node.lon})
                cur_node = cur_node.parent
            return {"success": 1, "route": final_road[::-1], "full_distance": total_distance}
        
        for new_node_id, inner_dict in cur_node.connections.items():
            new_node = inner_dict["node"]
            if new_node in closed_set:
                continue
            if new_node in open_list:
                if ((cur_node.g + inner_dict["distance"]) >= new_node.g ):
                    continue
            new_node.g = cur_node.g + inner_dict["distance"]
            new_node.h = heuristic_Manhattan_distance(new_node, end_node)
            new_node.f = new_node.g + new_node.h
            new_node.parent = cur_node
            heapq.heappush(open_list,new_node)

    #길이 연결되지 않았으면
    return {"success": 0}

def docs2nodes(docs: List[DocumentSnapshot]) -> List[Node]:
    '''
    노드들의 리스트를 반환
    '''
    res = list()
    for doc in docs:
        id = doc.id
        fields = doc.to_dict()
        connections = fields['connections']
        keys_to_extract = ['lat', 'lon']
        geometry = {key: fields[key] for key in keys_to_extract}
        node = Node(id, geometry, connections)
        res.append(node)
    return res

def get_nearest_node(nodes: List[Node], start_lat: float, start_lon: float) -> tuple[Node, float]:
    '''
    선형 검색으로 가장 가까운 노드 탐색. 더 가까운 알고리즘 있으면 대체할 것
    '''
    min = -1
    arg_min: Optional[Node] = None
    for node in nodes:
        dist = get_distance(node.lat, node.lon, start_lat, start_lon)
        if min == -1 or dist < min:
            arg_min = node
            min = dist
    return (arg_min, min)

app = initialize_app()

@https_fn.on_call()
def on_request_example(req: https_fn.CallableRequest) -> dict:
    firestore_client = firestore.client()    # firestore 클라이언트 선언
    
    start_point = req.data.get('StartPoint')
    if not start_point: return {"Error": "StartPoint is nor given."}, 400
    end_point = req.data.get('EndPoint')
    if not end_point: return {"Error": "EndPoint is not given."}, 400

    # 경로 찾기 시작점
    start_lat = start_point.get("lat")
    start_lon = start_point.get("lon")
    if start_lat is None or start_lon is None: return {"Error": "StartPoint must include 'lat' and 'lon' fields."}, 400
    
    # 경로 찾기 도착점
    end_lat = end_point.get("lat")
    end_lon = end_point.get("lon")
    if end_lat is None or end_lon is None: return {"Error": "EndPoint must include 'lat' and 'lon' fields."}, 400

    # 시작점에서 가까운 노드 찾기 위한 쿼리 요청
    collection_ref = firestore_client.collection('map_data')  # collection_ref 는 CollectionReference 객체임
    query_start = (   #query_start는 Query 객체임
        collection_ref
        .where("lat", ">=", start_lat - 0.05)
        .where("lat", "<=", start_lat + 0.05)
        .where("lon", "<=", start_lon + 0.05)
        .where("lon", ">=", start_lon - 0.05)
    )   # 시작 좌표 부근에서만 노드 호출
    docs = query_start.get() # docs는 QueryResultsList[DocumentSnapshot] 객체
    if not docs: return{"Error": "No near nodes from the start point are found."}, 400

    # 시작점에서 가장 가까운 노드 찾기
    nodes = docs2nodes(docs)   # 문서들을 Node 클래스로 변경
    nearest_start_node, start_dist = get_nearest_node(nodes, start_lat, start_lon)    # 가장 가까운 노드 반환

    # 도착점에서 가장 가까운 노드 찾기
    query_end = (
        collection_ref
        .where("lat", ">=", end_lat - 0.05)
        .where("lat", "<=", end_lat + 0.05)
        .where("lon", "<=", end_lon + 0.05)
        .where("lon", ">=", end_lon - 0.05)
    )   # 시작 좌표 부근에서만 노드 호출
    docs = query_end.get() # docs는 QueryResultsList[DocumentSnapshot] 객체
    if not docs: return{"Error": "No near nodes from the end point are found."}, 400

    # 시작점에서 가장 가까운 노드 찾기
    nodes = docs2nodes(docs)   # 문서들을 Node 클래스로 변경
    nearest_end_node, end_dist = get_nearest_node(nodes, end_lat, end_lon)    # 가장 가까운 노드 반환

    # 노드-노드 길찾기
    pathresult = astar_road_finder(start_node=nearest_start_node, end_node=nearest_end_node)

    return pathresult

