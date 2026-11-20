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
