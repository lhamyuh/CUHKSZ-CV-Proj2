#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
VIEW=$(python - <<'PY' | tail -1
import json, numpy as np
d=json.load(open('/root/autodl-tmp/CIE6004_ASGN2/runs/fusion/path_h.json'))
M=np.array(d['views'][0]['world_to_camera']); C=-M[:3,:3].T@M[:3,3]
print(','.join('%.4f'%x for x in C))
PY
)
for tag in a b; do
  if [ "$tag" = "a" ]; then DG=0.55; SS=0.85; SL=0.28; SW=0.17; SO=0.45; else DG=0.62; SS=0.90; SL=0.26; SW=0.16; SO=0.40; fi
  python code/phong_fusion.py --scene $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply \
    --object $ROOT/runs/obj_d2/point_cloud/iteration_30000/point_cloud_smooth.ply \
    --placement $ROOT/preview/placement_h.json --view_pos="$VIEW" \
    --ka 0.62 --kd 0.55 --ks 0.08 --shininess 24 --clearance_pct 6 --weighted_contact 1 \
    --base_align 1 --base_mode percentile --scale_boost 1.30 --opacity_add 0.9 --deglare $DG \
    --shadow_strength $SS --shadow_len $SL --shadow_wid $SW --shadow_offset $SO \
    --ao_strength 0.60 --ao_radius 0.20 \
    --out_scene $ROOT/runs/fusion/pr_$tag.ply --out_placement $ROOT/preview/pr_$tag.json 2>&1 | tail -2
  python code/render_views.py --ply $ROOT/runs/fusion/pr_$tag.ply --cameras $ROOT/runs/fusion/one.json --out $ROOT/runs/fusion/probe_pr$tag --bg 0 2>&1 | tail -1
  rm -f $ROOT/runs/fusion/pr_$tag.ply
done
python - <<'PY'
from PIL import Image, ImageDraw
R='/root/autodl-tmp/CIE6004_ASGN2'; G=f'{R}/preview'
ims=[]
for n,t in (('a','deglare 0.55, shadow 0.85'),('b','deglare 0.62, shadow 0.90')):
    im=Image.open(f'{R}/runs/fusion/probe_pr{n}/frame_000.png').convert('RGB').crop((250,260,850,680)).resize((600,420), Image.LANCZOS)
    c=Image.new('RGB',(600,444),'white'); c.paste(im,(0,24)); ImageDraw.Draw(c).text((6,6),t,fill='black'); ims.append(c)
row=Image.new('RGB',(1200,444),'white')
for i,c in enumerate(ims): row.paste(c,(i*600,0))
row.save(f'{G}/deglare_variants.jpg', quality=88); print('ok')
PY
echo PROBE_DEGLARE_DONE