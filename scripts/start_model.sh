#!/bin/bash
# start_model.sh
# Starts the llama.cpp server inside the gemma2-vllm Docker container
# Usage: ./start_model.sh

MODEL="/workspace/your-model.gguf"
CONTAINER="gemma2-vllm"
PORT=8000

docker start $CONTAINER

docker exec -it $CONTAINER bash -c "
cd /workspace/llama.cpp && \
HIP_VISIBLE_DEVICES=0 ./build/bin/llama-server \
  -m $MODEL \
  -ngl 99 \
  --host 0.0.0.0 \
  --port $PORT
"
