#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
INIT=$ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined.ply
echo "=== smooth the initial model (stronger) ==="
python code/smooth_object.py --ply $INIT --out $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_smooth2.ply \
  --k 12 --color_alpha 0.7 --opacity_beta 0.7 --scale_clamp 2.0 --scale_alpha 0.5 2>&1 | tail -2
python code/render_views.py --ply $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_smooth2.ply \
  --cameras $ROOT/runs/obj_w/orbit_probe.json --out $ROOT/runs/fusion/orb_sm2 --bg 1 2>&1 | tail -1
echo "=== fusion probe: brighter object, tighter shadow ==="
VIEW=$(python - <<'PY' | tail -1
import json, numpy as np
d=json.load(open('/root/autodl-tmp/CIE6004_ASGN2/runs/fusion/path_h.json'))
M=np.array(d['views'][0]['world_to_camera']); C=-M[:3,:3].T@M[:3,3]
print(','.join('%.4f'%x for x in C))
PY
)
python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
  --object $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_smooth2.ply \
  --placement $ROOT/preview/placement_h.json --view_pos="$VIEW" \
  --ka 0.62 --kd 0.55 --ks 0.08 --shininess 24 --clearance_pct 6 --weighted_contact 1 \
  --base_align 1 --base_mode percentile --scale_boost 1.25 --opacity_add 1.0 --deglare 0.45 --gain 1.6 \
  --shadow_strength 0.90 --shadow_len 0.22 --shadow_wid 0.14 --shadow_offset 0.35 \
  --ao_strength 0.35 --ao_radius 0.14 \
  --out_scene $ROOT/runs/fusion/newc.ply --out_placement $ROOT/preview/placement_newc.json 2>&1 | tail -5
python code/render_views.py --ply $ROOT/runs/fusion/newc.ply --cameras $ROOT/runs/fusion/one.json --out $ROOT/runs/fusion/probe_newc --bg 0 2>&1 | tail -1
python - <<'PY'
import glob
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
rows=[]
for tag,name in (('init','initial'),('cur','current'),('sm2','initial + strong smoothing')):
    fs=sorted(glob.glob(f'{R}/runs/fusion/orb_{tag}/*.png'))[:4]
    if not fs: continue
    ims=[Image.open(f).convert('RGB').resize((260,int(260*720/406)), Image.LANCZOS) for f in fs]
    row=Image.new('RGB',(4*260,ims[0].height+22),'white')
    for i,im in enumerate(ims): row.paste(im,(i*260,22))
    ImageDraw.Draw(row).text((6,5),name,fill='black'); rows.append(row)
sheet=Image.new('RGB',(1040,sum(r.height for r in rows)),'white'); y=0
for r in rows: sheet.paste(r,(0,y)); y+=r.height
sheet.save(f'{G}/B_versions2.jpg', quality=88)
im=Image.open(f'{R}/runs/fusion/probe_newc/frame_000.png').convert('RGB')
im.crop((250,260,850,680)).resize((760,532), Image.LANCZOS).save(f'{G}/C_newc.jpg', quality=86)
print('ok')
PY
echo PROBE_BC_DONE