#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
OUT=$ROOT/deliver/records_226010334_LinyuYANG
rm -rf $OUT; mkdir -p $OUT/{models,configs,logs,sfm,code}
cp $ROOT/runs/garden_base/point_cloud/iteration_30000/point_cloud.ply $OUT/models/garden_base_30k.ply
cp $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_smooth3.ply $OUT/models/object_delivered.ply
cp $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud_refined.ply $OUT/models/object_refined.ply
cp $ROOT/runs/obj_w/point_cloud/iteration_30000/point_cloud.ply $OUT/models/object_raw_30k.ply 2>/dev/null || true
cp $ROOT/runs/garden_base/cfg_args $OUT/configs/garden_base_cfg_args
cp $ROOT/runs/obj_w/cfg_args $OUT/configs/obj_w_cfg_args
cp $ROOT/data_object/split.json $OUT/configs/object_split.json
cp $ROOT/data_object/train/sparse/0/*.bin $OUT/sfm/ 2>/dev/null || true
cp $ROOT/logs/garden_base.log $OUT/logs/ 2>/dev/null || true
cp $ROOT/logs/obj_w.log $OUT/logs/ 2>/dev/null || true
cp $ROOT/runs/garden_base/loss.csv $OUT/logs/ 2>/dev/null || true
cp $ROOT/code/*.py $OUT/code/ 2>/dev/null || true
cp -r $ROOT/../remote_sh_snapshot $OUT/ 2>/dev/null || true
git -C $ROOT/gs/repo rev-parse HEAD > $OUT/configs/gs_commit.txt 2>/dev/null || true
python - <<PY
import hashlib, os, json
root = "$OUT"
lines = []
for dp, dn, fn in os.walk(root):
    for f in sorted(fn):
        p = os.path.join(dp, f)
        h = hashlib.sha256(open(p, "rb").read()).hexdigest()
        lines.append("%s  %s" % (h, os.path.relpath(p, root)))
open(os.path.join(root, "SHA256SUMS"), "w").write("\n".join(lines) + "\n")
print("hashed", len(lines), "files")
PY
cd $ROOT/deliver
tar -czf records_226010334_LinyuYANG.tar.gz records_226010334_LinyuYANG
ls -lh records_226010334_LinyuYANG.tar.gz
du -sh records_226010334_LinyuYANG
echo RECORDS_DONE