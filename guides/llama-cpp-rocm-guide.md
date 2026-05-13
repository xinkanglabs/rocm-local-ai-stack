
[llama-cpp-rocm-guide.md](https://github.com/user-attachments/files/27696934/llama-cpp-rocm-guide.md)
# llama.cpp ROCm Build Guide

AMD RX 7900 XTX (gfx1100) + ROCm 7.2.3

---

## Prerequisites

- AMD GPU (tested on RX 7900 XTX / gfx1100)
- ROCm 7.2.3+
- Docker (recommended)
- cmake, git

---

## Docker Setup (Recommended)

ROCm inside Docker is more stable than bare metal.

```bash
docker run -it \
  --device=/dev/kfd \
  --device=/dev/dri/card0 \
  --device=/dev/dri/card1 \
  --device=/dev/dri/renderD128 \
  --device=/dev/dri/renderD129 \
  --group-add video \
  -v /home/$USER/ai_work:/workspace \
  -p 8000:8000 \
  --name gemma2-vllm \
  rocm/pytorch:latest bash
```

---

## Build llama.cpp with ROCm HIP

```bash
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp

cmake -B build \
  -DGGML_HIP=ON \
  -DAMDGPU_TARGETS="gfx1100" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=/opt/rocm/bin/hipcc \
  -DCMAKE_CXX_COMPILER=/opt/rocm/bin/hipcc \
  -DCMAKE_PREFIX_PATH=/opt/rocm-7.2.3

cmake --build build --config Release -j$(nproc)
```

> **Critical:** `-DGGML_HIP=ON` is the flag that enables GPU support.
> Without it, the build succeeds but silently falls back to CPU. No warning.

---

## Verify GPU Build

```bash
cat build/CMakeCache.txt | grep "GGML_HIP:BOOL"
# Expected: GGML_HIP:BOOL=ON
```

---

## Run Model (Server Mode)

```bash
HIP_VISIBLE_DEVICES=0 ./build/bin/llama-server \
  -m /workspace/your-model.gguf \
  -ngl 99 \
  --host 0.0.0.0 \
  --port 8000
```

## Run Model (CLI Mode)

```bash
HIP_VISIBLE_DEVICES=0 ./build/bin/llama-cli \
  -m /workspace/your-model.gguf \
  -ngl 99 -cnv
```

---

## Important Flags

| Flag | Purpose |
|---|---|
| `HIP_VISIBLE_DEVICES=0` | Use GPU 0 only — prevents ROCm from picking up CPU iGPU as a second device |
| `-ngl 99` | Load all layers to GPU — without this, runs on CPU regardless of build |

---

## GPU Architecture Reference

| GPU | gfx code |
|---|---|
| RX 7900 XTX / XT | gfx1100 |
| RX 7800 XT / 7700 XT | gfx1101 |
| RX 6900 / 6800 XT | gfx1030 |
| RX 6700 XT | gfx1031 |

---

## Startup Script

```bash
#!/bin/bash
docker start gemma2-vllm
docker exec -it gemma2-vllm bash -c "
cd /workspace/llama.cpp && \
HIP_VISIBLE_DEVICES=0 ./build/bin/llama-server \
  -m /workspace/your-model.gguf \
  -ngl 99 \
  --host 0.0.0.0 \
  --port 8000
"
```

Save as `start_model.sh`, then:

```bash
chmod +x start_model.sh
./start_model.sh
```

---

## Benchmark

```bash
HIP_VISIBLE_DEVICES=0 ./build/bin/llama-bench \
  -m /workspace/your-model.gguf \
  -ngl 99
```

Example results (Gemma 4 26B A4B Q4_K_M):

| Test | t/s |
|---|---|
| pp512 (prefill) | ~3355 t/s |
| tg128 (generation) | ~102 t/s |
