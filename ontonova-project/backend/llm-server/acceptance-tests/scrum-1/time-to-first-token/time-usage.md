# TIEMPO EN COLD-START
(ontonova-llm) ubu@DESKTOP-0TOPMR0:~/tfm/ontonova-llm$ python3 acceptance-tests/scrum-1/time-to-first-token/main.py
⚡ Initiating latency test for Acceptance Criterion 2...

==================================================
📊 VALIDATION RESULTS
==================================================
🔹 Endpoint evaluated:     http://localhost:8000/v1/chat/completions
🔹 Model in VRAM:        Qwen/Qwen3-14B-AWQ
🔹 Model response:  <think> Okay, the user is asking for a
⏱️ Total time (TTFT):   0.3882 segundos
==================================================
✅ ACCEPTANCE CRITERION 2: ACHIEVED! (Below 2s)

# TIEMPO EN WARM-START
ubu@DESKTOP-0TOPMR0:~/tfm/ontonova-llm$ python3 acceptance-tests/scrum-1/time-to-first-token/main.py
⚡ Initiating latency test for Acceptance Criterion 2...

==================================================
📊 VALIDATION RESULTS
==================================================
🔹 Endpoint evaluated:     http://localhost:8000/v1/chat/completions
🔹 Model in VRAM:        Qwen/Qwen3-14B-AWQ
🔹 Model response:  <think> Okay, the user is asking for a
⏱️ Total time (TTFT):   0.4916 segundos
==================================================
✅ ACCEPTANCE CRITERION 2: ACHIEVED! (Below 2s)