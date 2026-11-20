# What is (and is not) in this repository

The repository keeps **source, configs, report and small evidence**. Everything that is
generated, heavy, or third-party is excluded and should be published as a GitHub **Release**
asset or kept on a cloud drive.

## Tracked (2.4 MB, 117 files)

| path | why it is in git |
|---|---|
| `remote/code/` | the pipeline scripts (camera loader, dataset builder, pruning, fusion, rendering, metrics, gallery) |
| `remote/*.sh` | the exact commands executed on the server, numbered in order |
| `tools_local/` | offline checks (pose convention, table plane, placement generation) |
| `submission/report/` | LaTeX source + compiled `main.pdf` |
| `submission/report/fig/*.jpg`, `loss.png` | figures referenced by `main.tex` |
| `submission/README.md` | reproducibility README |
| `EXPERIMENT_PLAN.md`, `VERIFY_GUIDE.md`, `README.md` | plan, review guide, repo overview |
| `object_split.json`, `metrics_val.json` (if present) | small numeric artefacts |

## Excluded — publish separately

| path | size | recommendation |
|---|---|---|
| `submission/StudentID_Name.zip` | 47 MB | **GitHub Release asset** (single file, versioned) |
| `submission/StudentID_Name/` | 48 MB | already inside the zip; do not duplicate |
| ├─ `renders/` (12 PNG, 1297x840) | 24 MB | inside zip |
| ├─ `scene/orbit.mp4` | 11.3 MB | inside zip |
| ├─ `fusion/orbit.mp4` | 5.0 MB | inside zip |
| └─ `evidence/` (orbit.gif, loss.csv/png, stages, ablation, bonus) | 6.6 MB | inside zip |
| `Assignment2_release/` and `.zip` | 293 MB | **course material — never push**; keep local only |
| `assets/`, `preview/`, `figures/` | 3–9 MB | scratch/inspection copies; safe to delete |
| `tjumian.pdf` | 36 MB | personal thesis, unrelated to this repo |

## Why not Git LFS?

LFS would version the videos, but the grading artefact is a single zip anyway. A Release asset
is simpler, has no bandwidth quota surprises for the reviewer, and keeps `git clone` fast.

## Suggested release

Tag `v1.0-submission` and attach:

1. `StudentID_Name.zip` (47 MB) — the actual submission.
2. optional `review_gallery.tar.gz` (23 MB, server-side gallery with contact sheets and videos).

```bash
# once the local tag exists
git tag -a v1.0-submission -m "Submission package (media attached as release assets)"
git push origin main --tags
# then, in the GitHub UI: Releases -> Draft a new release -> attach the zip
```
