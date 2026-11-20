# CIE 6004 Assignment 2 — Garden 3DGS, object reconstruction, fusion

This repository keeps the code, report source and experiment notes for Assignment 2.
Large course data, rendered videos and intermediate images are **not** tracked; they live
in the submission zip and on the GPU server.

## Layout

| path | content |
|---|---|
| `remote/code/` | pipeline scripts (camera loader, object prep, masks, dataset builder, pruning, fusion, rendering, metrics, gallery) |
| `remote/*.sh` | the exact shell scripts executed on the server, in order (venv, build, training, evaluation, fusion) |
| `tools_local/` | offline checks run on the workstation (pose convention, table plane fit, placement generation) |
| `submission/report/` | CVPR LaTeX source (`main.tex`, `main.bib`) and compiled `main.pdf` |
| `submission/fig/` | report figures (JPG/PNG referenced by `main.tex`) |
| `submission/README.md` | reproducibility README submitted with the assignment |
| `submission/StudentID_Name/` | submission tree (code only; media excluded) |
| `EXPERIMENT_PLAN.md` | plan, gates, experiment matrix written before the runs |
| `VERIFY_GUIDE.md` | manual + quantitative verification guide |

## Headline numbers

| item | value |
|---|---|
| Garden validation (12 views) | PSNR 27.27 / SSIM 0.8668 / LPIPS 0.0764 (baseline 25.73 / 0.7925 / 0.1757) |
| Garden training | 30k iters, 1297x840, 4.17M Gaussians, 21 min on H800 80GB |
| Object split | train 285 / val 33 / test 164 frames, 8-frame gaps |
| Object SfM | 498/498 frames registered, 10,939 points, 0.61 px reprojection |
| Mask ablation | masked PSNR 16.23 -> 18.23 dB with +2 px dilation, same budget |
| Fusion | 4.29M Gaussians, 240 frames, 24 fps, 10 s, 1280x720 |

## Reproduce

See `submission/README.md`; the scripts in `remote/` are numbered in execution order
(`01_venv.sh` ... `67_gallery.sh`).

## Environment

PyTorch 2.1.2+cu118, CUDA 11.8, 3DGS commit `54c035f`, COLMAP 3.7 (CPU), Ubuntu 22.04,
NVIDIA H800 PCIe 80 GB.
