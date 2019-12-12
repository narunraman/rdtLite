

import ctypes

feedcamflow = ctypes.CDLL('./camper.so')
disclosed_entites = {}
disclosed_activities = {}

def disclose_realtime_entities(node_id, node_string):
    print(node_string)
    disclosed_entities[node_id] = feedcamflow.cam_entity(node_string)

def disclose_realtime_activities(node_id, node_string):
    disclosed_activities[node_id] = feedcamflow.cam_activity(node_string)

# print(disclosed_activities)
