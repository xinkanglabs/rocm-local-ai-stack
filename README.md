Readme · MDCopyrocm-local-ai-stack
AMD RX 7900 XTX + ROCm local AI stack — llama.cpp, vLLM, Open WebUI
Personal documentation of a fully local AI inference setup running on consumer AMD hardware.

Hardware
ComponentSpecGPUAMD Radeon RX 7900 XTX (24GB / gfx1100)CPUAMD Ryzen 9 9950X3DRAM64GB+OSUbuntu 24.04.2 LTSROCm7.2.3

Benchmark Results
ModelEnginePrecisionPP (Read)TG (Write)Qwen2.5-7B-InstructvLLM (ROCm)FP16~3410 t/s~56 t/sGemma 4 26B A4Bllama.cpp (HIP)Q4_K_M~3355 t/s~102 t/sGemma 2 9Bllama.cpp (HIP)Q4_K_M~2773 t/s~79 t/s

PP = Prompt Processing (prefill speed)
TG = Token Generation (decode speed)


Stack
PurposeToolLocal chat inferencellama.cpp (GGML_HIP=ON)Server-mode inferencevLLM (ROCm)Browser UIOpen WebUIContainerDocker + rocm/pytorch:latest

Guides

llama.cpp ROCm Build Guide
vLLM + Qwen2.5 + Open WebUI Setup

Scripts

start_model.sh — One-command model startup
build_llama.sh — llama.cpp ROCm build


Model
Gemma 4 26B A4B quantized on this setup using llama.cpp.
Original 48GB → 16GB Q4_K_M.
👉 HuggingFace: rakisis-core/Gemma-4-26B-A4B-Q4K_M-GGUF

Key Notes

GGML_HIP=ON is critical — without it, llama.cpp builds fine but silently runs on CPU
HIP_VISIBLE_DEVICES=0 — prevents ROCm from picking up CPU iGPU as a second device
-ngl 99 — loads all layers to GPU, required for actual GPU inference


XinXin-Kang / Xinkang Labs 🌐 xinkanglabs.com.au
