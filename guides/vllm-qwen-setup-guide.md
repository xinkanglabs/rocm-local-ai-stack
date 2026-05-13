vLLM + Qwen2.5 + Open WebUI Setup Guide
AMD RX 7900 XTX (gfx1100) + ROCm + vLLM + Open WebUI

Overview
A fully local OpenAI-compatible AI server with:
·	High-speed inference
·	Long context handling
·	Multi-agent compatibility
·	OpenAI API compatibility
·	Browser-based chat UI
·	ROCm GPU acceleration

Hardware & Software
Component	Spec
GPU	AMD Radeon RX 7900 XTX 24GB
CPU	AMD Ryzen series
RAM	64GB+ recommended
OS	Ubuntu 24.04 LTS

Software Stack: ROCm · Docker · vLLM ROCm · Open WebUI · Qwen2.5-7B-Instruct

Folder Structure
~/ai_work/
├── vllm_models/
│   └── Qwen2.5-7B-Instruct/
├── llama.cpp/
├── benchmark/
└── logs/

Keep llama.cpp GGUF models and vLLM FP16 models in separate directories.

Step 1 — Install Docker
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

Re-login after adding user to docker group.

Step 2 — Verify ROCm Devices
ls /dev/kfd
ls /dev/dri


Step 3 — Create Working Directory
mkdir -p ~/ai_work/vllm_models


Step 4 — Download Qwen2.5-7B-Instruct
hf download Qwen/Qwen2.5-7B-Instruct \
  --local-dir ~/ai_work/vllm_models/Qwen2.5-7B-Instruct

Expected files:
config.json
model-00001-of-00004.safetensors
model-00002-of-00004.safetensors
model-00003-of-00004.safetensors
model-00004-of-00004.safetensors
tokenizer.json


Step 5 — Create Docker Network
docker network create ai-net

This allows Open WebUI, vLLM, and future agent containers to communicate through container DNS.

Step 6 — Run vLLM ROCm Container
docker run -it --rm \
  --network ai-net \
  --name vllm-qwen \
  --entrypoint /bin/bash \
  --device=/dev/kfd \
  --device=/dev/dri \
  --group-add video \
  --ipc=host \
  -p 8001:8000 \
  -v ~/ai_work/vllm_models:/models \
  vllm/vllm-openai-rocm:latest


Step 7 — Start Qwen in vLLM
Inside the container:
vllm serve /models/Qwen2.5-7B-Instruct \
  --host 0.0.0.0 \
  --port 8000 \
  --dtype float16 \
  --gpu-memory-utilization 0.90 \
  --max-model-len 8192 \
  --max-num-seqs 8 \
  --enforce-eager


Step 8 — Verify vLLM Server
curl http://localhost:8001/v1/models


Step 9 — Chat Test
curl http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "/models/Qwen2.5-7B-Instruct",
    "messages": [
      {"role": "user", "content": "Introduce yourself in Korean."}
    ],
    "max_tokens": 128,
    "temperature": 0.7
  }'


Step 10 — Install Open WebUI
docker run -d \
  --network ai-net \
  --name open-webui-vllm \
  -p 8080:8080 \
  -e ENABLE_SIGNUP=True \
  -v open-webui:/app/backend/data \
  ghcr.io/open-webui/open-webui:main


Step 11 — Connect Open WebUI to vLLM
Open http://localhost:8080, create admin account, then:
Settings → Connections → OpenAI API

Base URL: http://vllm-qwen:8000/v1
API Key:  EMPTY

Important: Browser uses localhost:8001, containers use http://vllm-qwen:8000

Benchmarking
Write / Decode Speed
TIMEFORMAT='%3R'; time curl -s http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model":"/models/Qwen2.5-7B-Instruct",
    "messages":[{"role":"user","content":"Explain ROCm and vLLM in detail."}],
    "max_tokens":1024
  }' > benchmark.json

cat benchmark.json | jq '.usage'

Example: 1024 tokens / 18.128s = 56.5 tok/s
Read / Prefill Speed
python3 - << 'PY'
import json
prompt = ("Explain ROCm and vLLM. " * 500)
payload = {
    "model": "/models/Qwen2.5-7B-Instruct",
    "messages": [{"role": "user", "content": prompt}],
    "max_tokens": 16
}
with open("payload2.json", "w") as f:
    json.dump(payload, f)
PY

TIMEFORMAT='%3R'; time curl -s -X POST \
  http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  --data-binary @payload2.json > readbench2.json

cat readbench2.json | jq '.usage'

Example: 4031 tokens / 1.182s = 3410 tok/s

Benchmark Results
Metric	Qwen2.5-7B FP16 + vLLM
Read / Prefill	~3410 tok/s
Write / Decode	~56.5 tok/s


Common Problems
Port Already Allocated
docker ps
docker stop <container>

Open WebUI Signup Not Appearing
-e ENABLE_SIGNUP=True

Old Config Remaining
docker volume rm open-webui

Context Length Error
This model's maximum context length is 8192 tokens

Context = input tokens + output tokens. Measured in tokens, not characters.

Docker Networking Notes
Access	URL
From browser	http://localhost:8001
Container to container	http://vllm-qwen:8000


vLLM vs llama.cpp
	vLLM	llama.cpp
Best for	Multi-user, API servers, RAG	Local single-user, low-latency
Format	FP16 / BF16	GGUF quantized
PagedAttention	Yes	No
Prefill speed	Very fast	Fast


Optional Security
# Localhost only
-p 127.0.0.1:8001:8000
-p 127.0.0.1:8080:8080

# Disable signup after setup
-e ENABLE_SIGNUP=False

# Add API key
--api-key YOUR_SECRET_KEY


Useful Docker Commands
docker ps                    # list running containers
docker stop vllm-qwen        # stop container
docker rm vllm-qwen          # remove container
docker logs -f vllm-qwen     # view logs

