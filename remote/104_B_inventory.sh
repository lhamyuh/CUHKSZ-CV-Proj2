#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
cd $ROOT
source env/bin/activate
python - <<'PY'
import json, os, glob
R='/root/autodl-tmp/CIE6004_ASGN2'
sp=json.load(open(f'{R}/data_object/split.json'))
print('clips:', sp['clips'], 'fps', sp['fps'], 'val_gap_frames', sp['val_gap_frames'])
for k in ('train','val','test'):
    ids=sp[k]; clips={}
    for i in ids: clips[i.split('_')[0]]=clips.get(i.split('_')[0],0)+1
    print(f'{k}: {len(ids)} frames  per clip {clips}  first {ids[0]} last {ids[-1]}')
print('train images on disk:', len(glob.glob(f'{R}/data_object/train/images/*.png')))
print('train dirs:', os.listdir(f'{R}/data_object/train'))
from PIL import Image
im=Image.open(glob.glob(f'{R}/data_object/train/images/*.png')[0]); print('train image size/mode:', im.size, im.mode)
for name in ('val_cameras.json','test_cameras.json'):
    p=f'{R}/data_object/{name}'
    if os.path.exists(p):
        d=json.load(open(p)); print(name,'views',len(d['views']),'WH',d['width'],d['height'],'f',round(d['fx'],2))
# COLMAP train model
import sys; sys.path.insert(0, f'{R}/code')
from colmap_io import read_cameras, read_images, read_points3d
cams=read_cameras(f'{R}/data_object/train/sparse/0/cameras.bin')
imgs=read_images(f'{R}/data_object/train/sparse/0/images.bin')
pts=read_points3d(f'{R}/data_object/train/sparse/0/points3D.bin')
print('train sparse: cameras',len(cams),'images(poses)',len(imgs),'points',len(pts))
# full SfM model
cams2=read_cameras(f'{R}/runs/obj_sfm_m/sparse/0/cameras.bin')
imgs2=read_images(f'{R}/runs/obj_sfm_m/sparse/0/images.bin')
print('full SfM: cameras',len(cams2),'registered images',len(imgs2))
print('mask files:', len(glob.glob(f'{R}/data_object/masks/*.png')))
print('source frames extracted:', len(glob.glob(f'{R}/data_object/frames/*.jpg')))
PY
echo INV_DONE