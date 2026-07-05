curl http://localhost:8000/v1/chat/completions   -H "Content-Type: application/json"   -d '{
    "model": "Qwen/Qwen3-14B-AWQ",
    "messages": [
      {"role": "system", "content": "Eres el motor OntoNova."},
      {"role": "user", "content": "Prueba de sistema. Responde OK."}
    ]
  }'