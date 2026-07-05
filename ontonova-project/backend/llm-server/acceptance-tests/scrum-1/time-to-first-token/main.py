import time
import requests

URL = "http://localhost:8000/v1/chat/completions"

payload = {
    "model": "Qwen/Qwen3-14B-AWQ",
    "messages": [
        {"role": "user", "content": "Performance test. Respond only with the word OK."}
    ],
    "temperature": 0.0,
    "max_tokens": 10,
    "stream": False
}

print("⚡ Initiating latency test for Acceptance Criterion 2...")
start_time = time.time()

try:
    response = requests.post(URL, json=payload, timeout=10)
    end_time = time.time()
    
    ttft = end_time - start_time
    response_json = response.json()
    output_text = response_json['choices'][0]['message']['content']
    
    print("\n==================================================")
    print("📊 VALIDATION RESULTS")
    print("==================================================")
    print(f"🔹 Endpoint evaluated:     {URL}")
    print(f"🔹 Model in VRAM:        Qwen/Qwen3-14B-AWQ")
    print(f"🔹 Model response:  {output_text.strip()}")
    print(f"⏱️ Total time (TTFT):   {ttft:.4f} seconds")
    print("==================================================")
    
    if ttft < 2.0:
        print("✅ ACCEPTANCE CRITERION 2: ACHIEVED! (Below 2s)")
    else:
        print("❌ ACCEPTANCE CRITERION 2: FAILED (Exceeds 2s. Requires optimization or warmup)")

except Exception as e:
    print(f"❌ Error in endpoint connection: {e}")