#!/bin/bash

# 1. Detect and unload active Ollama models from VRAM
echo "Unloading active models..."
for model in $(ollama ps | awk 'NR>1 {print $1}'); do
  ollama stop "$model"
done

# 2. Stop the background service
echo "Stopping Ollama service..."
sudo systemctl stop ollama

# 3. Aggressive cleanup (just in case)
echo "Killing any remaining AI processes..."
sudo pkill -9 ollama 2>/dev/null

# 4. Optional: Reset the GPU memory (if supported by your BIOS)
# This clears the VRAM buffer entirely
echo "Flushing GPU memory..."
sudo nvidia-smi --gpu-reset -i 0 2>/dev/null
sudo nvidia-smi -rac 2>/dev/null

echo "--- GPU is now chilled and VRAM is free! ---"
