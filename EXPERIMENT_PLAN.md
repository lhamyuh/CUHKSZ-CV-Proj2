# Project 2 实验计划（Garden 重建 · 物体重建 · 融合）

> 目标：在 H800 80GB 上以约 3–4 GPU 小时完成 CIE 6004 Assignment 2 全部任务（100 分 + 10 bonus），
> 并保证每个数字都能追溯到一条命令、一个日志、一个 commit。
> 本文件是执行清单，也是报告写作的素材索引。

---

## 0. 评分映射：每一项分数对应哪个产物

| 评分项 | 分 | 产物 | 验收标准 |
|---|---|---|---|
| A1 可复现训练 | 10 | `code/`、`README.md` 的完整命令、`logs/train.log`、`cfg_args` | 固定 seed 重跑 2k 迭代，train PSNR 与首次误差 <0.2 dB |
| A2 位姿 + 规定视频 | 10 | `renders/DSC*.png`×12、`scene/orbit.mp4` | 12 张 1297×840 原生 RGB；240 帧 / 24 fps / 10.0 s / 1280×720；位姿逐帧对齐 `trajectory/garden.json` |
| A3 指标 | 20 | `metrics_val.json`、test 渲染、最难视图对比图 | val PSNR/SSIM/LPIPS 三项均不差于 baseline（25.726 / 0.7925 / 0.1757） |
| B1 split + 位姿 | 8 | `object_split.json`、`evidence/poses.md` | train/val/test 互斥且非空；val 弧两侧各 ≥8 帧（1 s）间隔；COLMAP 重投影误差 <1.5 px |
| B2 物体重建 + orbit | 10 | `evidence/orbit.gif` | 360° 环绕、无背景残留、轮廓连续、光照稳定 |
| B3 训练证据 | 7 | `evidence/loss.csv`、`loss.png`、`stages.png` | loss 曲线单调下降段清晰；7k/15k/30k 三个 step 同一机位 |
| B4 受控实验 | 10 | `evidence/ablation.png` + 报告第 3 节 | 同 split、同预算、只改一个变量；两个固定视角 baseline vs 改动；给出改进/退化与残余失败 |
| C1 尺度与空间关系 | 10 | `fusion/orbit.mp4`、`fusion/placement.json` | 物体底面与桌面接触可见；尺寸/朝向在视觉上合理（相机宽度约 13.6 cm） |
| C2 深度序（遮挡—重现） | 10 | 同上 | 至少有 15 帧物体被完全遮挡，且末尾完全露出；遮挡比例可量化 |
| C3 平稳运镜 | 5 | 同上 | 6–12 s 连续镜头，无跳切、无抖动突变 |
| Bonus | ≤10 | `evidence/bonus_*.png/mp4` + 报告第 5 节 | 同视角 basic vs improved；改进可见；解释与改动一一对应 |

**一票否决项**：render 尺寸不是 1297×840、PNG 非 RGB、视频不是 24 fps / 240 帧、split 有交集、`placement.json` 不是 4×4。
提交前必须 `python tools/validate_submission.py ...` 返回 0。

---

## 1. 现状：哪些能复用，哪些必须重跑

复用（不消耗 GPU 时间）：

- 本地 `D:\3DGS_Project\python\gaussian-splatting`（原版 3DGS）与 `D:\Essay\TJU\...\gaussian-splatting`（4D 分支，含相机插值、后处理）。
- 本地 `3dgs_env`（torch 2.5.1+cu121 + 已编译 rasterizer），只用来做**离线数据检查**；服务器上重建独立环境。
- 论文中的调参经验、失败诊断结构、loss/TensorBoard 证据格式。

必须重跑（旧结果不能替代）：

1. Garden 30k 训练（你此前只在公开 185 张上试过，且未产出点云）。
2. 物体三段的 SfM 位姿、mask、物体 3DGS。
3. 融合渲染与运镜。

**红线**：`D:\3DGS_Project\data\...\garden\images_4` 里有 val/test 的 24 张参考图，只允许用课程 `val/reference`；test 参考图一律不看、不用、不参与任何拟合。

---

## 2. 服务器目录（真实名字，不再伪装）

```
/root/autodl-tmp/CIE6004_ASGN2/
├── release/          # 课程原始文件（161 图 + sparse + val/test + trajectory + object/*.mp4）
├── env/              # python -m venv，torch + 编译后的 rasterizer
├── gs/               # 官方 3DGS，记录 git commit
├── code/             # 自己写的 prep / sfm / mask / render / fusion 脚本（提交用）
├── runs/             # garden_base、garden_tune_*、obj_base、obj_h1 ...
├── preview/          # contact sheet、低码率样片（6006 端口静态服务）
├── logs/             # train.log、metrics.csv、experiments.md
└── out/              # 最终 StudentID_Name/ 打包（本地再建）
```

环境：`venv`（不写 conda），`torch==2.3.1+cu121`（或镜像自带版本），`diff-gaussian-rasterization` + `simple-knn` 编译到该 venv。
关键：`nvcc` 版本必须与 `torch.version.cuda` 一致，否则编译出来的扩展 import 即崩。

---

## 3. 阶段 0：环境、数据与坐标系校验（约 40 min，无卡模式可做大部分）

| ID | 内容 | 产物 | 通过条件 |
|---|---|---|---|
| E0.1 | 建 venv、装 torch、编译两个 CUDA 扩展 | `env/`、`logs/build.log` | `import diff_gaussian_rasterization` 成功且能前向 |
| E0.2 | 数据完整性：161/12/12、1297×840、单相机 PINHOLE、内参 1/4 缩放 | `logs/data_check.txt` | 数量、尺寸、`fx≈961.41` 全部吻合 |
| E0.3 | 写 `code/cameras.py`：release 的 `world_to_camera` → 3DGS `Camera(R,T,FovX,FovY)`；`cx,cy` 校验 | 模块 + 单测 | 反投影已知点误差 <1e-3 |
| E0.4 | **位姿校验**：用 baseline 的 val 渲染图与 reference 对齐比较（不是训练），确认我的 loader 与官方一致 | `preview/pose_check.jpg` | 渲染结果与 `val/baseline` 的差异仅来自模型质量，无整体偏移/翻转 |
| E0.5 | 基准测试：2k 迭代，测 `s/iter`、显存峰值、并发上限 | `logs/bench.txt` | 得到每卡并发数（预期 4–5） |

> E0.4 是最重要的一次性检查：位姿转置、y 轴翻转、T 符号错，都会让指标掉到 12–15 dB；先花 10 分钟排掉，后面所有实验才可信。

---

## 4. 阶段 A：Garden 重建（约 70 min GPU）

### 4.1 实验矩阵

| ID | 变量 | 设置 | 目的 | 预算 |
|---|---|---|---|---|
| **A0** | 基线（官方默认） | 30k，SH=3，r=1，`densify_until=15k`，`grad_thresh=2e-4` | 拿到第一个可比数字 | 25 min |
| A1 | densify 阈值 | 1e-4 vs 2e-4 vs 4e-4 | 细结构/过密权衡 | 3×7k，并行 |
| A2 | densify 停止点 | 15k vs 20k | 后段细节是否还在长 | 2×7k，并行 |
| A3 | 分辨率 | r=1 vs r=2（渲染仍按原生） | 量化"降采样代价"，也给报告一个对照 | 2×7k，并行 |
| A4 | 迭代数 | 30k vs 45k | 指标是否还在涨 | 1×45k |

短实验（7k）只用于**排序**，不用于报最终数字；每个配置都在同一批 val 视图上评估，指标写入 `logs/results.csv`。

### 4.2 决策规则

- A0 达到或超过 baseline → 直接进入 A4（判断是否值得加迭代），再定稿。
- A0 低于 baseline 超过 0.5 dB → 先查三件事：位姿（E0.4）、分辨率是否被意外缩放、`--eval` 是否误开导致 161 张里被抽走训练图。
- A1/A2 最好成绩比 A0 高 <0.05 dB → 视为噪声，保留 A0 默认参数（可复现性优先）。
- 定稿配置必须**只跑一次**并在报告中注明这是最终结果，不重复挑选。

### 4.3 产物

1. `renders/<stem>.png` ×12（test，1297×840，RGB PNG）。
2. `scene/orbit.mp4`：严格读 `trajectory/garden.json` 的 240 个 `world_to_camera`，内参 `fx=fy=1410, cx=640, cy=360`，1280×720，24 fps，10 s，H.264。
3. `metrics_val.json`：官方 `tools/evaluate.py` 输出（含 12 个视图逐项指标）。
4. 最难视图：取 val 中 PSNR 最低的一张，做 `reference | ours | baseline` 三联 + 2× 局部放大（木纹、花茎），配一句成因分析（这是 A 的 20 分里"show one view where your reconstruction struggles"的硬性要求）。
5. `logs/loss.csv/png`（从 TensorBoard event 或训练日志导出）。

### 4.4 视频与 PNG 的两套相机处理

- `trajectory/garden.json` 是 1280×720、`fx=1410`，与训练相机（1297×840、`fx=961`）不同 → 必须**单独构造 Camera 对象**，不能复用训练相机。
- `test/cameras.json` 是 1297×840、`fx=961.41/962.80`，直接构造。
- 两者都是 `world_to_camera` 4×4（OpenCV，列向量）→ `R = M[:3,:3]`、`T = M[:3,3]`；不要取逆，不要转置（3DGS 的 `Camera` 内部就是 `world2view`）。

---

## 5. 阶段 B：物体重建与受控实验（约 60 min GPU + 30 min CPU）

### 5.1 选定对象：camera（Olympus OM-2）

理由：纹理强（刻度、logo、金属反光）→ SfM 稳；刚体、缺陷可定义；guide 的 Figure 2 示例就是它；放进花园木桌、被花瓶遮挡在叙事上自然。
白毛绒作为备选（弱纹理、白平衡漂移，SfM 风险高）。

### 5.2 帧与 split（8 fps，1 s = 8 帧）

原始素材：`1975` 198 帧、`1976` 136 帧、`1977` 164 帧。

| split | 内容 | 帧数 | 说明 |
|---|---|---|---|
| train | `1975_0000–0197` + `1976_0000–0031` + `1976_0081–0135` | 198+32+55 = **285** | 两段开发片段 |
| val | `1976_0040–0072` | **33** | 连续弧，前 gap `0032–0039`、后 gap `0073–0080`（各 8 帧 = 1 s） |
| test | `1977_0000–0163` | **164** | 保留片段，只用于最终评估与"documented pose registration" |

`object_split.json` 用 `<clip>_<frame4>` 字符串作为帧 ID（如 `"1976_0052"`），附带 `fps`、`clip_duration`、`val_gap_frames` 字段方便 TA 核对。
**三个数组必须互斥**（`validate_submission.py` 会校验）。

### 5.3 SfM 与位姿

两阶段，避免 482 张图的穷举匹配把时间吃光：

1. **子集建图**：每 2 帧取 1（约 241 张）→ COLMAP GPU SIFT → exhaustive matching → mapper。
2. **全量注册**：固定内参（单相机、pinhole、406×720），用 `image_registrator` 把剩余帧注册进已有模型。
3. 输出：`runs/obj_sfm/sparse/0/`（cameras/images/points3D），写 `evidence/poses.md` 记录相机模型、重投影误差、注册成功率。

回退：COLMAP 失败 → hloc（SuperPoint + LightGlue + NetVLAD 检索）产出 pycolmap 模型；再失败 → 只用 dev 片段建模，test 片段仅做定性对比并在报告中说明。

### 5.4 掩码

- 首选 SAM2（首帧点选 → 视频传播），时序一致；次选 `rembg`(u2net) + 最大连通域 + 形态学。
- 抽检 12 帧叠加图（`preview/mask_check.jpg`），要求轮廓包住整机、不吞手指/床单褶皱。
- 掩码用途：① 训练时背景抑制；② 报告 Figure 的 source/mask/render 三联。

### 5.5 训练（含自己的改动，需在报告里声明）

基线 `obj_base`：30k，SH=3，原图 406×720，mask 加权光度损失（`loss = (L1 + λ·(1-SSIM)) * M`，`M` 为前景掩码），背景置黑，COLMAP 点初始化时只保留落在掩码内的点。
这是相对官方 3DGS 的**改动 1**，正好对上 guide 的"compare source, foreground mask and object render"。

### 5.6 缺陷诊断与受控实验

先看 `obj_base` 的 360° orbit，按下面优先级选**一个**可见缺陷（并记录选它的证据帧）：

| 候选 | 现象 | 可能成因 | 单变量改动 | 验收指标 |
|---|---|---|---|---|
| H1 | 轮廓被"削"一圈（掩码把边缘当背景） | 硬掩码 + 边界像素计为背景，梯度把边缘高斯压掉 | mask 膨胀 2 px + 边缘软权重 | 轮廓 IoU（vs val 掩码）↑，val PSNR 不降 |
| H2 | 快门钮/背带环/镜头刻度等薄结构缺失 | `densify_grad_threshold` 全局偏大，薄结构梯度小 | 2e-4 → 1e-4（预算不变） | 局部 crop 的 SSIM ↑，点数 ↑ 但 <1.5× |
| H3 | 金属高光在某些角度碎裂成浮点 | 视角相关外观欠拟合 | 提高训练分辨率（预算变量，需声明） | 高光区 LPIPS ↓ |

规则：**只改一个变量**，其余（split、30k 预算、seed、分辨率——除非分辨率就是变量）全部锁死；在**同一对固定视角**渲染 baseline 与改动；给出改进、退化、以及一个仍然存在的失败。
一个"证伪了假设"的结果同样能拿分析分——所以宁可把假设写清楚，不要事后编故事。

### 5.7 产物

- `evidence/orbit.gif`：360°、24 视角、512×512（或 360×640），循环。
- `evidence/loss.csv` + `loss.png`：从训练日志导出（iteration, total, l1, ssim, psnr, points）。
- `evidence/stages.png`：7k / 15k / 30k 三个 checkpoint，同一固定机位。
- `evidence/ablation.png`：两视角 × (baseline, 改动) + 局部放大。
- `object_split.json`、`evidence/poses.md`。

---

## 6. 阶段 C：放置与融合（约 40 min GPU）

### 6.1 尺度与位姿估计

1. **桌面平面**：在 Garden 高斯中取桌面板区域（花瓶周围、法向朝上的点），RANSAC 拟合平面 `n·x=d`，得到桌面高度与法向。
2. **场景尺度**：以圆桌直径 ≈1.6 m（或花瓶高 ≈0.35 m）折算"场景单位/米"；两个参照互相校验，偏差 >20% 时人工目测修正。
3. **物体真实尺寸**：OM-2 机身 136×83×50 mm；从物体模型包围盒得到"物体单位/米"。
4. **`object_to_scene`**：均匀缩放 `s = (场景单位/米)/(物体单位/米)` + 桌面上的平移 + 绕竖直轴旋转，使镜头朝向桌外、机身侧面朝向初始相机。写成 4×4 列向量矩阵。
5. 视觉验收：物体宽度在 1280×720 画面里约 60–90 px（按相机距离估算），与桌面比例自然。

### 6.2 遮挡—重现的运镜设计

3 个关键帧，Catmull-Rom 插值位置 + slerp 插值朝向，look-at 指向物体中心：

- **K0（0 s）**：桌外 1.5 m、高 1.3 m，同时看到桌面、花瓶、物体——交代放置与接触。
- **K1（~4 s）**：相机绕到花瓶另一侧，花瓶在物体前形成遮挡。
- **K2（~9 s）**：继续横移，物体从花瓶边缘重新露出，背景是花园。

**可量化的遮挡检查**（写进 `code/fusion/visibility.py`）：
逐帧渲染"只含物体"的 alpha 与"只含场景"的深度，统计 `occluded_ratio = 物体像素中深度大于场景深度的比例`。
验收：存在连续 ≥15 帧 `occluded_ratio > 0.95`（完全遮挡），且最后一帧 `< 0.05`（完全可见）；否则调整 K1 或物体位置。

输出：`fusion/orbit.mp4`（1280×720，24 fps，8–10 s，H.264，CRF 20），`fusion/placement.json`（`object_to_scene` + 两个坐标系说明 + 渲染命令）。

---

## 7. Bonus：融合渲染改进（约 30 min）

| ID | 问题 | 改动 | 证据 |
|---|---|---|---|
| **Bonus** | 物体像"贴"在桌上：无接触阴影、亮度比桌面亮、桌纹从物体边缘透出 | ① 桌面高斯按到物体底部的距离做径向变暗（模拟接触阴影）；② 物体 SH 直流分量向局部场景均值做颜色/亮度匹配；③ 剔除物体低不透明度浮点、提高边缘不透明度 | 同机位、同放置的 basic vs improved 对比图 + 2× 放大；视频同一时间戳对比 |

评分点：5 分看"改进是否可见"，5 分看"解释与证据是否对得上改动"。所以每张对比图都标注改动编号，报告里逐条对应。

---

## 8. 汇总时间表（H800，GPU 计费时间）

| 时间 | 阶段 | 产出 | GPU |
|---|---|---|---|
| 0:00–0:40 | E0 环境 + 校验 + 基准 | venv、data_check、bench | 0.3 h |
| 0:40–1:05 | A0 30k | 第一个 val 指标 | 0.4 h |
| 1:05–1:30 | A1–A3 并行 7k | 参数排序 | 0.4 h |
| 1:30–2:00 | A4/A 定稿 + 12 PNG + 轨迹视频 | Task A 完成 | 0.5 h |
| 2:00–2:30 | B 抽帧 + SfM + 掩码 | 位姿、mask | 0.3 h |
| 2:30–2:55 | B 基线训练 + orbit | obj_base | 0.4 h |
| 2:55–3:20 | B 受控实验（2 组并行）+ stages | ablation、stages | 0.4 h |
| 3:20–4:00 | C 放置 + 运镜 + 渲染 + bonus | fusion、bonus | 0.7 h |
| 之后 | 报告、打包、校验（CPU 本地） | report.pdf、zip | 0 |

预留 1 小时缓冲给 SfM 失败重试。**GPU 空转是大忌**：每批实验提交后立刻把下一批脚本准备好。

---

## 9. 风险与回退

| 风险 | 概率 | 影响 | 回退 |
|---|---|---|---|
| 扩展编译失败（nvcc 与 torch CUDA 不匹配） | 中 | 阻塞一切 | 换镜像重装 torch（锁 cu121）；记录到 README |
| COLMAP 跨片段注册失败 | 中 | B 无法评测 test | hloc/LightGlue；或仅 dev 建模 + 定性对比 |
| 掩码吞掉镜头/手指 | 中 | 轮廓缺陷、训练背景污染 | SAM2 传播；手修 5–10 帧关键掩码 |
| Garden 指标低于 baseline | 低 | 少拿分 | 查位姿/分辨率；46k 迭代；`--antialiasing`（如有） |
| 遮挡不成立（物体一直被挡住或一直可见） | 中 | C 的 10 分 | 用 `visibility.py` 反馈调 K1/K2 或物体位置 |
| 报告超 5 页 | 中 | 格式罚分 | 先写图表再写字；附录放补充材料 |

---

## 10. 报告结构（CVPR 模板，正文 ≤5 页）

| 页 | 内容 | 必须出现的证据 |
|---|---|---|
| 1 | 任务、方法总览、与 baseline 的设置差异 | 系统流程图；引用 3DGS + Mip-NeRF 360 |
| 2 | Garden：指标表、逐视图曲线、最难视图三联放大 | `metrics_val.json`；`reference/ours/baseline` |
| 3 | 物体：split 与位姿、mask 训练改动、缺陷假设与受控实验 | source/mask/render；ablation 两视角 |
| 4 | 融合：`object_to_scene`、遮挡比例曲线、时间戳 0/4/9 s 帧 | 遮挡帧 + 重现帧；视频时间戳引用 |
| 5 | Bonus、失败分析、可复现信息（硬件、时间、迭代数、命令） | basic vs improved；剩余失败 |

---

## 11. 提交前检查清单

- [ ] 12 张 test PNG：1297×840、RGB、PNG、文件名与 `test/cameras.json` 一致
- [ ] `scene/orbit.mp4`：240 帧、24 fps、10.0 s、1280×720、按轨迹顺序
- [ ] `fusion/orbit.mp4`：6–12 s、≥24 fps、≥720p、遮挡 ≥15 帧且末尾重现
- [ ] `object_split.json` 三段互斥、val 两侧各 ≥8 帧 gap
- [ ] `fusion/placement.json` 含 4×4 `object_to_scene` + 坐标系说明
- [ ] `evidence/` 五件套齐全且能对应报告段落
- [ ] `README.md`：环境、commit、seed、硬件、时间、全部命令
- [ ] `validate_submission.py` 返回 0；zip 为 `StudentID_Name/...`，55–110 MB
