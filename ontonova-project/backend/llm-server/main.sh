python3 -m vllm.entrypoints.openai.api_server \
    --model Qwen/Qwen3-14B-AWQ \
    --dtype float16 \
    --gpu-memory-utilization 0.7322 \
    --max-model-len 16384 \
    --port 8000