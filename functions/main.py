# Deploy with `firebase deploy` or `firebase deploy --only functions`
# For more information, see https://firebase.google.com/docs/functions/manage-functions
# and https://firebase.google.com/docs/functions/callable

from pandas import DataFrame
from sklearn.cluster import KMeans
from firebase_functions.firestore_fn import on_document_updated
from zoneinfo import ZoneInfo

from firebase_admin import initialize_app, firestore, auth
from firebase_functions import https_fn, scheduler_fn, options
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud.firestore import CollectionReference

from typing import Dict, List, TypedDict
from geopy.distance import distance
import heapq
from numpy import array, dot

AStarReturn = TypedDict("AStarReturn", {"route": List[Dict[str, float]], "path": List[Dict[str, float]], "full_distance": float})
RequestRouteReturn = TypedDict("RequestRouteReturn", {"route": List[Dict[str, float]], "path": List[Dict[str, float]], "full_distance": float})


initialize_app()
firestore_client = firestore.client()


def get_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    # 두 지점 사이의 거리 계산
    coords1 = (lat1, lon1)
    coords2 = (lat2, lon2)
    return round(distance(coords1, coords2).m, 3)


class Node:
    def __init__(self, id: int, geometry: Dict[str, float], connections, parent=None):
        self.id: int = id
        self.lat: float = geometry["lat"]
        self.lon: float = geometry["lon"]
        self.connections = connections
        self.g: float = 0
        self.h: float = 90000
        self.f: float = 0
        self.parent = parent

    def __lt__(self, other):
        return self.f < other.f

    def __eq__(self, other):
        return self.id == other.id


def heuristic_Manhattan_distance(cur_node: Node, end_node: Node) -> float:
    # 현재 노드에서 목표 노드까지의 맨하탄 거리 계산
    mid_location = (cur_node.lat, end_node.lon)
    manhattan_dist = distance((cur_node.lat, cur_node.lon), mid_location).m + distance(mid_location, (end_node.lat, end_node.lon)).meters
    return manhattan_dist


def heuristic_preference_distance(cur_node: Node, end_node: Node, group_road_type, group_preference) -> float:
    manhattan_dist = heuristic_Manhattan_distance(cur_node, end_node)
    # next node의 해당 group의 preference 추가
    # print(group_road_type)

    feature_num = len(group_preference)  # feature_num을 고정 값인 preference를 다 더한 값을 사용하면 어떻게 될까.. 음수가 될 수도 있긴한데 음수를 0으로 빼버리면?
    pref_sum = abs(sum(group_preference))
    lt = array(group_road_type)
    gp = array(group_preference)
    road_preference = dot(lt, gp)

    if all(abs(x) < 0.3 for x in group_preference):  # group의 preference이기 때문에 이미 0.3보다 작은 애들은 preference를 끄고 진행한다고 생각하고 코드 짜기
        pref_sum = feature_num

    # feature 개수로 나눈 대로 scaling
    pref_dist = manhattan_dist - (manhattan_dist / pref_sum) * road_preference
    if pref_dist < 0:
        pref_dist = 0  # 휴리스틱이 항상 0 이상이도록

    return pref_dist


def astar_road_finder(collection_ref: CollectionReference, start_node: Node, end_node: Node, user_taste: bool, group_preference: List) -> AStarReturn:
    # A* 알고리즘을 사용하여 시작 노드에서 도착 노드까지의 최단 경로 찾기
    open_list: List[Node] = []
    closed_set = set()
    start_node.h = heuristic_Manhattan_distance(start_node, end_node)
    heapq.heappush(open_list, start_node)

    while open_list != []:
        cur_node = heapq.heappop(open_list)
        closed_set.add(cur_node.id)

        if cur_node == end_node:
            final_road = []
            final_path = [{"node_id": cur_node.id, "lat": cur_node.lat, "lon": cur_node.lon}]
            total_distance = cur_node.g
            while cur_node is not None:
                final_road.append({"node_id": cur_node.id, "lat": cur_node.lat, "lon": cur_node.lon})
                if cur_node.parent is not None:
                    final_path += [{"node_id": cur_node.id, "lat": branch["lat"], "lon": branch["lon"]} for branch in cur_node.connections[str(cur_node.parent.id)]["routes"][0]["branch"][1:]]
                cur_node = cur_node.parent
            return {"route": final_road[::-1], "path": final_path[::-1], "full_distance": total_distance}

        for id, inner_dict in cur_node.connections.items():
            new_node = create_node(collection_ref, id)
            if new_node.id in closed_set:
                continue
            if new_node in open_list:
                new_node = open_list[open_list.index(new_node)]
                if (cur_node.g + inner_dict["distance"]) >= new_node.g:
                    continue
            new_node.g = cur_node.g + inner_dict["distance"]
            if user_taste:
                new_node.h = heuristic_preference_distance(new_node, end_node, inner_dict["attributes"], group_preference)
            else:
                new_node.h = heuristic_Manhattan_distance(new_node, end_node)
            new_node.f = new_node.g + new_node.h
            new_node.parent = cur_node
            heapq.heappush(open_list, new_node)

    # 길이 연결되지 않았으면 에러 발생
    raise https_fn.HttpsError(
        code=https_fn.FunctionsErrorCode.INTERNAL,
        message="No route was found between the start and end points.",
    )


def get_nearest_node(collection_ref: CollectionReference, lat: float, lon: float) -> tuple[int, float]:
    # 선형 검색으로 가장 가까운 노드 탐색. TODO 더 가까운 알고리즘 있으면 대체할 것
    # 기준 좌표 부근에서 후보 노드들 query
    query_start = (
        collection_ref.where(filter=FieldFilter("lat", ">=", lat - 0.005))
        .where(filter=FieldFilter("lat", "<=", lat + 0.005))
        .where(filter=FieldFilter("lon", "<=", lon + 0.005))
        .where(filter=FieldFilter("lon", ">=", lon - 0.005))
    )
    docs = [doc for doc in query_start.stream()]

    # 해당 범위에 노드가 없으면 에러 발생
    if not docs:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="No nodes near the end point were found.",
        )

    # 후보 노드들 중 가장 가까운 노드 찾기
    min = float("inf")
    node_min_id: int = -1
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


def create_node(collection_ref: CollectionReference, id: int) -> Node:
    # Firestore에서 노드 생성
    doc = collection_ref.document(str(id)).get()
    inner_dict = doc.to_dict()
    node = Node(int(id), {"lat": inner_dict["lat"], "lon": inner_dict["lon"]}, inner_dict["connections"])
    return node


@https_fn.on_call(timeout_sec=120, memory=options.MemoryOption.MB_512)
def request_route(req: https_fn.CallableRequest) -> RequestRouteReturn:
    try:  # 요청 데이터 파싱
        start_point = req.data["StartPoint"]
        end_point = req.data["EndPoint"]
        user_taste = req.data["UserTaste"]
        user_group = req.data["UserGroup"]
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
        user_taste = bool(user_taste)
    except ValueError as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=(e.args[0]),
        )

    try:  # 노드 맵 생성
        collection_ref = firestore_client.collection("map_data_v2")
        group_preference = firestore_client.collection("Clusters").document(user_group).get().to_dict()["centroid"]
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=(e.args[0]),
        )

    try:  # 시작점에서 가장 가까운 노드 찾기
        nearest_start_node_id, start_dist = get_nearest_node(collection_ref, start_lat, start_lon)
        nearest_start_node = create_node(collection_ref, nearest_start_node_id)
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"No nodes near the start point were found. Error: {e.args[0]}",
        )

    try:  # 도착점에서 가장 가까운 노드 찾기
        nearest_end_node_id, end_dist = get_nearest_node(collection_ref, end_lat, end_lon)
        nearest_end_node = create_node(collection_ref, nearest_end_node_id)
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"No nodes near the end point were found. Error: {e.args[0]}",
        )

    try:  # 시작노드-도착노드 길찾기
        result = astar_road_finder(collection_ref, start_node=nearest_start_node, end_node=nearest_end_node, user_taste=user_taste, group_preference=[])
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"No route was found between the start and end points. Error: {e.args[0]}",
        )

    # 시작점과 도착점을 최종 경로에 추가
    try:
        start_point_node = [{"node_id": None, "lat": start_lat, "lon": start_lon}]
        end_point_node = [{"node_id": None, "lat": end_lat, "lon": end_lon}]
        route = start_point_node + result["route"] + end_point_node
        path = start_point_node + result["path"] + end_point_node
        full_distance = start_dist + result["full_distance"] + end_dist
        return {"route": route, "path": path, "full_distance": full_distance}
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=(e.args[0]),
        )


@https_fn.on_call(min_instances=1, timeout_sec=120, memory=options.MemoryOption.MB_512)
def request_route_debug(req: https_fn.CallableRequest) -> RequestRouteReturn:
    try:  # 요청 데이터 파싱
        start_point = req.data["StartPoint"]
        end_point = req.data["EndPoint"]
        user_taste = req.data["UserTaste"]
        user_group = req.data["UserGroup"]
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
        user_taste = bool(user_taste)
    except ValueError as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=(e.args[0]),
        )

    try:  # 노드 맵 생성
        collection_ref = firestore_client.collection("map_data_songdo")
        group_preference = firestore_client.collection("Clusters").document(user_group).get().to_dict()["centroid"]
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=(e.args[0]),
        )

    try:  # 시작점에서 가장 가까운 노드 찾기
        nearest_start_node_id, start_dist = get_nearest_node(collection_ref, start_lat, start_lon)
        nearest_start_node = create_node(collection_ref, nearest_start_node_id)
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"No nodes near the start point were found. Error: {e.args[0]}",
        )

    try:  # 도착점에서 가장 가까운 노드 찾기
        nearest_end_node_id, end_dist = get_nearest_node(collection_ref, end_lat, end_lon)
        nearest_end_node = create_node(collection_ref, nearest_end_node_id)
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"No nodes near the end point were found. Error: {e.args[0]}",
        )

    try:  # 시작노드-도착노드 길찾기
        result = astar_road_finder(collection_ref, start_node=nearest_start_node, end_node=nearest_end_node, user_taste=user_taste, group_preference=group_preference)
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"No route was found between the start and end points. Error: {e.args}",
        )

    # 시작점과 도착점을 최종 경로에 추가
    try:
        start_point_node = [{"node_id": None, "lat": start_lat, "lon": start_lon}]
        end_point_node = [{"node_id": None, "lat": end_lat, "lon": end_lon}]
        route = start_point_node + result["route"] + end_point_node
        path = start_point_node + result["path"] + end_point_node
        full_distance = start_dist + result["full_distance"] + end_dist
        return {"route": route, "path": path, "full_distance": full_distance}
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=(e.args[0]),
        )


@https_fn.on_call(memory=options.MemoryOption.MB_512)
def generate_custom_token(request: https_fn.CallableRequest):
    try:
        user_id = request.data["token"]
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f"Missing argument 'user_id' in request data. {e}",
        )

    try:
        token = auth.create_custom_token(user_id).decode("utf-8")
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Failed to create custom token. {e}",
        )

    return {"token": token}


class User:
    def __init__(self, uid: str, attributes: dict):
        self.uid = uid
        self.attributes = [value for _, value in attributes.items()]


# 클러스터링 진행하는 코드
@scheduler_fn.on_schedule(schedule="0 0 * * 0", timezone=ZoneInfo("Asia/Seoul"), memory=options.MemoryOption.MB_512)
def cluster_users(event: scheduler_fn.ScheduledEvent):
    users_ref = firestore_client.collection("users")

    docs = users_ref.select(["attributes"]).stream()  # docs는 제너레이터 객체. 좀 큰 데이터에서 받아올 때는 stream으로
    docs1 = firestore_client.collection("Clusters").get()  # docs1은 리스트 객체. 작은 데이터라 get으로

    Users = [User(doc.id, doc.to_dict()["attributes"]) for doc in docs]
    Datas = DataFrame.from_dict({user.uid: user.attributes for user in Users}, orient="index")
    num_users = len(Users)

    # 유저가 하나면 클러스터링을 진행하는 것이 아니라 그냥 그걸로 끝내기
    if num_users == 0:
        exit()

    if num_users == 1:
        users_ref.document(Users[0].uid).update({"label": 0})

        centroid = list(Users[0].attributes)
        data = {
            "centroid": centroid,
        }
        firestore_client.collection("Clusters").document(str(0)).set(data)
    elif not docs1:  # 이전에 클러스터링을 한 적이 없으면
        # N = 16으로 클러스터링
        kmeans = KMeans(n_clusters=16, init="k-means++", random_state=0).fit(Datas)
        labels = kmeans.labels_
        centroids = kmeans.cluster_centers_
        for i, user in enumerate(Users):
            users_ref.document(user.uid).update({"label": int(labels[i])})
        for i, centroid in enumerate(centroids):
            data = {
                "centroid": list(centroid),
            }
            firestore_client.collection("Clusters").document(str(i)).set(data)
    else:  # 이전에 클러스터링을 한 적이 있으면 그냥 클러스터링 다시 돌리기
        docs1_sorted = sorted(docs1, key=lambda x: int(x.id))
        centroids = [doc.to_dict()["centroid"] for doc in docs1_sorted]  # 이전의 중심점들 정보를 받아오기

        kmeans = KMeans(n_clusters=len(centroids), init=centroids, random_state=0).fit(Datas)
        labels0 = kmeans.labels_
        centroids0 = list(kmeans.cluster_centers_)

        for i, user in enumerate(Users):
            users_ref.document(user.uid).update({"label": int(labels0[i])})
        for i, centroid in enumerate(centroids0):
            data = {
                "centroid": list(centroid),
            }
            print(f"document {i} is updated to {data}")
            firestore_client.collection("Clusters").document(str(i)).set(data)


@on_document_updated(document="users/{user_id}", memory=options.MemoryOption.MB_512)
def assign_label(event) -> None:
    new_value = event.data.after
    prev_value = event.data.before
    if new_value.get("attributes") == prev_value.get("attributes"):
        return

    user_id = new_value.get("uid")
    attributes = new_value.get("attributes")
    # 각 중심점과 거리 비교하여 가장 가까운 중심점의 라벨을 할당
    clusters_ref = firestore_client.collection("Clusters")
    docs = clusters_ref.get()
    min_dist = float("inf")
    label = -1
    for doc in docs:
        dist = sum((a - b) ** 2 for a, b in zip(attributes, doc.to_dict()["centroid"]))
        if dist < min_dist:
            min_dist = dist
            label = doc.id

    firestore_client.collection("users").document(user_id).update({"label": int(label)})
