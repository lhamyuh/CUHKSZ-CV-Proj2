# Deliverables and records — 226010334 Linyu YANG

| item | where |
|---|---|
| graded archive (report, code, renders, evidence, fusion) | `submission/226010334_LinyuYANG.zip`, also Release asset `226010334_LinyuYANG.zip` |
| model weights, `cfg_args`, COLMAP model, logs, checksums | Release asset `records_226010334_LinyuYANG.tar.gz` (922 MB) and the server copy under `runs/` |
| report source | `submission/report/main.tex`, `main.bib` |
| pipeline code | `remote/code/`, `remote/*.sh` (execution order), `tools_local/` |
| provenance snapshot | `records/` (this folder): `MANIFEST.md`, `SHA256SUMS`, both `cfg_args`, `object_split.json`, 3DGS commit |

Release page: <https://github.com/lhamyuh/CUHKSZ-CV-Proj2/releases/tag/v2.0-final>

## After the GPU instance is released

The AutoDL instance was released after packaging, so nothing below depends on it any more.

| what | where |
|---|---|
| graded archive | `submission/226010334_LinyuYANG.zip` (local) and Release asset (same bytes) |
| model weights + configs + logs | `deliverables/records_226010334_LinyuYANG.tar.gz` (local, 922 MB) and Release asset (sha256 `3125d8f1…`) |
| from-scratch reproduction kit | Release asset `repro_226010334_LinyuYANG.tar.gz` (44 KB: `REPRODUCE.md`, `pip freeze`, CUDA/COLMAP/3DGS versions, frame list, mask checksums, metrics, fusion placement) |
| course data, template, clips | `Assignment2_release/` (local). Training and validation **photographs** are not kept locally because they are the course's own data; re-download them from the course portal if a full re-render is needed. Cameras, COLMAP sparse model, trajectory, template, tools and the three object clips are kept. |

## What the TA needs for a spot check

The guide asks us to keep the final scene and object models until grading is complete.
The archive `records_226010334_LinyuYANG.tar.gz` contains

- `models/garden_base_30k.ply` — delivered Garden model (4,173,282 Gaussians),
- `models/object_delivered.ply` — delivered object model (initial + light smoothing),
- `models/object_refined.ply`, `models/object_raw_30k.ply` — intermediate object states,
- `configs/` — `cfg_args` of both runs, `object_split.json`, 3DGS commit,
- `sfm/` — COLMAP model used for the object training set,
- `logs/`, `code/`, `SHA256SUMS`.

All checksums are in `records/SHA256SUMS`; verify with `sha256sum -c SHA256SUMS` inside the
extracted archive.

## Original files kept unmodified

- `data_object/frames/` — 498 extracted frames (8 fps) from the three supplied clips; never edited.
- `data_object/masks/` — u2netp masks; the +2 px dilation variant is written to a separate
  directory, so the originals stay untouched.
- `runs/obj_sfm_m/` — COLMAP model from the masked SfM run (used to build both object datasets).
- Training outputs are kept per run (`runs/*/point_cloud/iteration_*/`), so the pruning and
  smoothing stages can be re-derived from the raw 30k model.
