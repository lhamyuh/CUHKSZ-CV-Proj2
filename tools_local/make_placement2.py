"""Build candidate object_to_scene placements (yaw variants) for manual orientation pick.

Pruned-model PCA (runs/obj_w pruned):
  axis A (range 5.28) = body width   -> 136 mm
  axis B (range 2.99) = body height  ->  83 mm   => upright axis
  axis C (range 2.13) = lens depth   ->  55 mm
"""
import json
from pathlib import Path

import numpy as np

ASGN = Path(r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2")
OUT = ASGN / "preview"

table = json.loads((OUT / "table_geometry.json").read_text())
centre = np.array(table["centre"])
up_scene = np.array(table["normal"])
up_scene /= np.linalg.norm(up_scene)

A = np.array([-0.98, -0.15, -0.13]); A /= np.linalg.norm(A)   # width
B = np.array([0.051, -0.823, 0.566]); B /= np.linalg.norm(B)  # height (up)
C = np.array([-0.192, 0.548, 0.814]); C /= np.linalg.norm(C)  # depth / lens

c_obj = np.array([0.167, 2.487, 1.637])       # pruned centroid
width_units = 5.277
scale = 0.136 / width_units                    # body width = 13.6 cm
half_h = 0.5 * 2.989 * scale

traj = json.loads((ASGN / "Assignment2_release/trajectory/garden.json").read_text())
M0 = np.array(traj["views"][0]["world_to_camera"])
cam0 = -M0[:3, :3].T @ M0[:3, 3]

d = cam0 - centre
d = d - np.dot(d, up_scene) * up_scene
d /= np.linalg.norm(d)
P = centre + 0.45 * d + 0.008 * up_scene
t0 = P + half_h * up_scene

w1_base = np.cross(up_scene, d)
w1_base /= np.linalg.norm(w1_base)
# local frame: x->w1 (width), y->up_scene (height), z->w3 (lens depth)
w3_base = np.cross(w1_base, up_scene)

print("scale", round(scale, 5), "half height", round(half_h, 4))
for yaw in (0, 90, 180, 270):
    a = np.radians(yaw)
    w1 = np.cos(a) * w1_base + np.sin(a) * w3_base
    w3 = np.cross(w1, up_scene)
    R = np.stack([w1, up_scene, w3], axis=1)   # columns: local x,y,z -> world
    M = np.eye(4)
    M[:3, :3] = scale * R
    M[:3, 3] = t0 - scale * R @ c_obj
    rec = {"object_to_scene": M.tolist(), "scale": scale, "yaw_deg": yaw,
           "scene_up": up_scene.tolist(), "table_centre": centre.tolist(),
           "object_model": "runs/obj_w point_cloud_pruned.ply (camera, 30k, white bg, pruned)",
           "notes": "uniform-scale rigid transform acting on column vectors; p_scene = s R p_obj + t"}
    (OUT / f"placement_v2_yaw{yaw}.json").write_text(json.dumps(rec, indent=2))
print("written 4 candidates")
