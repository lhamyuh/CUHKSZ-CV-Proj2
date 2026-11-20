#!/usr/bin/env bash
set -u
cd /root/autodl-tmp/CIE6004_ASGN2
source env/bin/activate
python - <<'PY'
import importlib.util as u
mods = ["plyfile","cv2","tqdm","lpips","torchvision","scipy","matplotlib","imageio","pandas","PIL","sklearn"]
for m in mods:
    print(m, bool(u.find_spec(m)))
PY
if [ ! -d gs/repo/.git ]; then
  git clone --recursive https://github.com/graphdeco-inria/gaussian-splatting.git gs/repo 2>&1 | tail -5
fi
cd gs/repo && git log -1 --format="commit %H %ad" --date=short
ls submodules
