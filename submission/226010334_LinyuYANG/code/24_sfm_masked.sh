#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
D=$ROOT/runs/obj_sfm_m
MD=$ROOT/data_object/masks_colmap
rm -rf $D; mkdir -p $D/sparse $MD
for f in $ROOT/data_object/masks/*.png; do
  b=$(basename $f .png)
  ln -sf $f $MD/${b}.jpg.png
done
echo "mask links: $(ls $MD | wc -l)"
cd $D
colmap feature_extractor --database_path db.db --image_path $ROOT/data_object/frames \
  --ImageReader.single_camera 1 --ImageReader.camera_model PINHOLE \
  --ImageReader.mask_path $MD \
  --SiftExtraction.use_gpu 0 --SiftExtraction.num_threads 18 \
  --SiftExtraction.max_image_size 720 > feat.log 2>&1
echo "feat rc=$?"; tail -3 feat.log
colmap exhaustive_matcher --database_path db.db --SiftMatching.use_gpu 0 \
  --SiftMatching.num_threads 18 > match.log 2>&1
echo "match rc=$?"
colmap mapper --database_path db.db --image_path $ROOT/data_object/frames \
  --output_path sparse --Mapper.num_threads 18 > mapper.log 2>&1
echo "mapper rc=$?"; tail -3 mapper.log
for m in $D/sparse/*/; do echo -n "$m "; colmap model_analyzer --path $m 2>/dev/null | grep -E "Registered images|Points" | tr "\n" " "; echo; done
echo MASKED_SFM_DONE