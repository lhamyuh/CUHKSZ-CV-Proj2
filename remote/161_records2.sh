#!/usr/bin/env bash
set -uo pipefail
ROOT=/root/autodl-tmp/CIE6004_ASGN2
source $ROOT/env/bin/activate
OUT=$ROOT/deliver/records_226010334_LinyuYANG
python - <<PY
import hashlib, os
root = "$OUT"
lines = []
for dp, dn, fn in os.walk(root):
    for f in sorted(fn):
        p = os.path.join(dp, f)
        if f == "SHA256SUMS":
            continue
        h = hashlib.sha256(open(p, "rb").read()).hexdigest()
        lines.append("%s  %s" % (h, os.path.relpath(p, root)))
open(os.path.join(root, "SHA256SUMS"), "w").write("\n".join(lines) + "\n")
print("hashed", len(lines), "files")
PY
cat > $OUT/MANIFEST.md <<'MD'
# Records — CIE 6004 Assignment 2 (226010334 Linyu YANG)

Kept for TA code review and for reproducing the submitted renders.

| path | content |
|---|---|
| `models/garden_base_30k.ply` | delivered Garden model (4,173,282 Gaussians, 30k iters) |
| `models/object_delivered.ply` | delivered object model (initial + light smoothing) |
| `models/object_refined.ply` | object after opacity/scale refinement (before smoothing) |
| `models/object_raw_30k.ply` | raw 3DGS output before pruning |
| `configs/*_cfg_args` | exact 3DGS training configuration of both runs |
| `configs/object_split.json` | disjoint train/val/test frame IDs |
| `configs/gs_commit.txt` | graphdeco-inria/gaussian-splatting commit used |
| `sfm/*.bin` | COLMAP model used to build the object training set |
| `logs/` | training logs and the exported loss CSV |
| `code/` | snapshot of the pipeline scripts at submission time |
| `SHA256SUMS` | checksums of every file above |

Renders, videos and evidence are in `226010334_LinyuYANG.zip`; this bundle holds the
model weights that the guide asks us to keep locally until grading is complete.
MD
cd $ROOT/deliver
rm -f records_226010334_LinyuYANG.tar.gz
tar -czf records_226010334_LinyuYANG.tar.gz records_226010334_LinyuYANG
ls -lh records_226010334_LinyuYANG.tar.gz
sha256sum records_226010334_LinyuYANG.tar.gz | tee records_226010334_LinyuYANG.tar.gz.sha256
echo RECORDS2_DONE