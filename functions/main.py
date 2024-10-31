# Deploy with `firebase deploy` or `firebase deploy --only functions`
# For more information, see https://firebase.google.com/docs/functions/manage-functions
# and https://firebase.google.com/docs/functions/callable

from firebase_admin import initialize_app, firestore
from firebase_functions import https_fn
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud.firestore import CollectionReference

from typing import Dict, List
from geopy.distance import distance
import heapq


initialize_app()
firestore_client = firestore.client()


def get_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    # 두 지점 사이의 거리 계산
    coords1 = (lat1, lon1)
    coords2 = (lat2, lon2)
    return round(distance(coords1, coords2).m, 3)


class Node:
    def __init__(self, id: int, geometry: Dict[str, float], connections: Dict[int, Dict[str, float]] = {}, parent=None):
        self.id = id
        self.lat = geometry["lat"]
        self.lon = geometry["lon"]
        self.connections = connections
        self.g = 0
        self.h = 90000
        self.f = 0
        self.parent = parent

    def __lt__(self, other):
        return self.f < other.f


def heuristic_Manhattan_distance(cur_node: Node, end_node: Node) -> float:
    # 현재 노드에서 목표 노드까지의 맨하탄 거리 계산
    mid_location = (cur_node.lat, end_node.lon)
    manhattan_dist = distance((cur_node.lat, cur_node.lon), mid_location).m + distance(mid_location, (end_node.lat, end_node.lon)).meters
    return manhattan_dist


def astar_road_finder(start_node: Node, end_node: Node, use_sharing=False, user_taste=False) -> list:
    # A* 알고리즘을 사용하여 시작 노드에서 도착 노드까지의 최단 경로 찾기
    open_list = []
    closed_set = []
    start_node.h = heuristic_Manhattan_distance(start_node, end_node)
    heapq.heappush(open_list, start_node)

    while open_list != []:
        cur_node = heapq.heappop(open_list)
        closed_set.append(cur_node)

        if cur_node == end_node:
            final_road = []
            total_distance = cur_node.g
            while cur_node is not None:
                final_road.append({"node_id": cur_node.id, "lat": cur_node.lat, "lon": cur_node.lon})
                cur_node = cur_node.parent
            return {"route": final_road[::-1], "full_distance": total_distance}

        for inner_dict in cur_node.connections.values():
            new_node = inner_dict["node"]
            if new_node in closed_set:
                continue
            if new_node in open_list:
                if (cur_node.g + inner_dict["distance"]) >= new_node.g:
                    continue
            new_node.g = cur_node.g + inner_dict["distance"]
            new_node.h = heuristic_Manhattan_distance(new_node, end_node)
            new_node.f = new_node.g + new_node.h
            new_node.parent = cur_node
            heapq.heappush(open_list, new_node)

    # 길이 연결되지 않았으면
    raise https_fn.HttpsError


def get_nearest_node(collection_ref: CollectionReference, lat: float, lon: float) -> tuple[Node, float]:
    # 선형 검색으로 가장 가까운 노드 탐색. TODO 더 가까운 알고리즘 있으면 대체할 것
    # 기준 좌표 부근에서 후보 노드들 query
    query_start = (
        collection_ref.where(filter=FieldFilter("lat", ">=", lat - 0.05))
        .where(filter=FieldFilter("lat", "<=", lat + 0.05))
        .where(filter=FieldFilter("lon", "<=", lon + 0.05))
        .where(filter=FieldFilter("lon", ">=", lon - 0.05))
    )
    docs = [doc for doc in query_start.stream()]

    # 해당 범위에 노드가 없으면 에러 발생
    if not docs:
        raise https_fn.HttpsError

    # 후보 노드들 중 가장 가까운 노드 찾기
    min = float("inf")
    node_min_id: int = None
    for node_ref in docs:
        node_id = int(node_ref.id)
        node = node_ref.to_dict()
        dist = get_distance(node["lat"], node["lon"], lat, lon)
        if dist < min:
            node_min_id = node_id
            min = dist

    return (node_min_id, min)


def create_node_map(collection_ref: CollectionReference) -> dict[int, Node]:
    # Firestore에서 노드 맵 생성
    node_map = {int(doc.id): Node(int(doc.id), doc.to_dict(), doc.to_dict()["connections"]) for doc in collection_ref.stream()}
    for node in node_map.values():
        node.connections = {int(k): {"node": node_map[int(k)], "distance": v["distance"]} for k, v in node.connections.items()}
    return node_map


def request_route(req: https_fn.CallableRequest) -> dict:
    try:  # 요청 데이터 파싱
        start_point = req.data["StartPoint"]
        end_point = req.data["EndPoint"]
        use_sharing = req.data["UseSharing"]
        user_taste = req.data["UserTaste"]
    except KeyError as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=(f"Missing argument '{e}' in request data."),
        )

    try:  # 요청 데이터 유효성 검사
        start_lat = start_point["lat"]
        start_lon = start_point["lon"]
    except KeyError as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=(f"Missing argument '{e}' in start point."),
        )

    try:  # 요청 데이터 유효성 검사
        end_lat = end_point["lat"]
        end_lon = end_point["lon"]
    except KeyError as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=(f"Missing argument '{e}' in end point."),
        )

    try:  # 요청 데이터 타입 변환
        start_lat = float(start_lat)
        start_lon = float(start_lon)
        end_lat = float(end_lat)
        end_lon = float(end_lon)
        use_sharing = bool(use_sharing)
        user_taste = bool(user_taste)
    except ValueError as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=(e.args[0]),
        )

    try:  # 노드 맵 생성
        collection_ref = firestore_client.collection("map_data")
        node_map = create_node_map(collection_ref)
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=(e.args[0]),
        )

    try:  # 시작점에서 가장 가까운 노드 찾기
        nearest_start_node_id, start_dist = get_nearest_node(collection_ref, start_lat, start_lon)
        nearest_start_node = node_map[nearest_start_node_id]
    except https_fn.HttpsError:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="No nodes near the start point were found.",
        )

    try:  # 도착점에서 가장 가까운 노드 찾기
        nearest_end_node_id, end_dist = get_nearest_node(collection_ref, end_lat, end_lon)
        nearest_end_node = node_map[nearest_end_node_id]
    except https_fn.HttpsError:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="No nodes near the end point were found.",
        )

    try:  # 시작노드-도착노드 길찾기
        result = astar_road_finder(start_node=nearest_start_node, end_node=nearest_end_node)
    except https_fn.HttpsError:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="No route was found between the start and end points.",
        )

    # 시작점과 도착점을 최종 경로에 추가
    start_point_node = [{"node_id": None, "lat": start_lat, "lon": start_lon}]
    end_point_node = [{"node_id": None, "lat": end_lat, "lon": end_lon}]
    route = start_point_node + result["route"] + end_point_node
    full_distance = start_dist + result["full_distance"] + end_dist

    return {"route": route, "full_distance": full_distance}
