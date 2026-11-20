"""Build candidate object_to_scene placements (4 yaws) for manual orientation pick."""
import json
from pathlib import Path

import numpy as np

ASGN = Path(r"D:\Essay\CUHKSZ\AY2627Term1\Image Processing\Asgn2")
OUT = ASGN / "preview"

table = json.loads((OUT / "table_geometry.json").read_text())
centre = np.array(table["centre"])
up = np.array(table["normal"])
up /= np.linalg.norm(up)

# object PCA axes from runs/obj_w (largest, mid, smallest)
e1 = np.array([-0.9686, 0.239, -0.0685]); e1 /= np.linalg.norm(e1)
e2 = np.array([0.2433, 0.9679, -0.063]); e2 /= np.linalg.norm(e2)
e3 = np.array([-0.0512, 0.0776, 0.9957]); e3 /= np.linalg.norm(e3)
c_obj = np.array([0.5959, 2.2978, 1.7563])      # robust bbox centre of the object
height_units = 2.786 - (-1.767)                  # extent along e3
scale = 0.019
half_h = 0.5 * height_units * scale

traj = json.loads((ASGN / "Assignment2_release/trajectory/garden.json").read_text())
M0 = np.array(traj["views"][0]["world_to_camera"])
cam0 = -M0[:3, :3].T @ M0[:3, 3]

# place the object 0.45 scene units from the table centre, on the side of the first camera
d = cam0 - centre
d = d - np.dot(d, up) * up
d /= np.linalg.norm(d)
P = centre + 0.45 * d
P = P + 0.01 * up
t0 = P + half_h * up

w1_base = np.cross(up, d)
w1_base /= np.linalg.norm(w1_base)

print("scene up", np.round(up, 4), "place at", np.round(P, 4), "cam0", np.round(cam0, 3))
for yaw in (0, 90, 180, 270):
    a = np.radians(yaw)
    w1 = np.cos(a) * w1_base + np.sin(a) * np.cross(up, w1_base)
    w1 /= np.linalg.norm(w1)
    w2 = np.cross(up, w1)
    R = np.stack([w1, w2, up], axis=1)   # columns
    M = np.eye(4)
    M[:3, :3] = scale * R
    M[:3, 3] = t0 - scale * R @ c_obj
    rec = {"object_to_scene": M.tolist(), "scale": scale, "yaw_deg": yaw,
           "scene_up": up.tolist(), "table_centre": centre.tolist(),
           "object_model": "runs/obj_w (camera, 30k, white bg)",
           "notes": "uniform-scale rigid transform acting on column vectors"}
    (OUT / f"placement_yaw{yaw}.json").write_text(json.dumps(rec, indent=2))
    print("yaw", yaw, "->", OUT / f"placement_yaw{yaw}.json")
