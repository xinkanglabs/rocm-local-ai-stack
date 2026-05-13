#!/bin/bash
# build_llama.sh
# Builds llama.cpp with ROCm HIP support inside Docker container
# Usage: Run this inside the rocm/pytorch Docker container

set -e

cd /workspace/llama.cpp

echo "Removing old build..."
rm -rf build

echo "Configuring with ROCm HIP..."
cmake -B build \
  -DGGML_HIP=ON \
  -DAMDGPU_TARGETS="gfx1100" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=/opt/rocm/bin/hipcc \
  -DCMAKE_CXX_COMPILER=/opt/rocm/bin/hipcc \
  -DCMAKE_PREFIX_PATH=/opt/rocm-7.2.3

echo "Building..."
cmake --build build --config Release -j$(nproc)

echo "Verifying GPU support..."
cat build/CMakeCache.txt | grep "GGML_HIP:BOOL"

echo "Build complete."
echo "Binaries: /workspace/llama.cpp/build/bin/"
