#!/bin/bash
set -e

# Script to create test chats and log to MLflow
# Usage: ./scripts/create_test_chats.sh

API_URL="${API_URL:-http://127.0.0.1:8000}"
NUM_REQUESTS="${NUM_REQUESTS:-5}"

echo "🚀 Creating $NUM_REQUESTS test chat requests to $API_URL/chat"
echo ""

# Array of diverse prompts to test
PROMPTS=(
  "What is retrieval-augmented generation and why is it useful?"
  "Explain the concept of vector embeddings in one paragraph."
  "How does prompt engineering improve LLM outputs?"
  "What are the benefits of local model serving with Ollama?"
  "Describe the difference between fine-tuning and prompt engineering."
)

# Check if API is reachable
if ! curl -s "$API_URL/health" > /dev/null 2>&1; then
  echo "❌ API not reachable at $API_URL"
  echo "   Run: make run-local"
  exit 1
fi

echo "✅ API is running"
echo ""

# Make requests with different prompts
for i in $(seq 1 $NUM_REQUESTS); do
  PROMPT_IDX=$(( (i - 1) % ${#PROMPTS[@]} ))
  PROMPT="${PROMPTS[$PROMPT_IDX]}"
  TEMP=$(echo "scale=2; 0.3 + (0.5 * ($i - 1) / ($NUM_REQUESTS - 1))" | bc)
  
  echo "📝 Request $i/$NUM_REQUESTS (temp=$TEMP)"
  echo "   Prompt: $PROMPT"
  
  # Make POST request and time it using jq for JSON generation
  START=$(date +%s%N)
  RESPONSE=$(jq -n --arg prompt "$PROMPT" --arg temp "$TEMP" \
    '{prompt: $prompt, temperature: ($temp | tonumber)}' \
    | curl -s -X POST "$API_URL/chat" \
    -H 'Content-Type: application/json' \
    -d @- \
    2>/dev/null || echo '{"error":"Request failed"}')
  END=$(date +%s%N)
  
  # Calculate latency in ms
  LATENCY=$(( (END - START) / 1000000 ))
  
  # Extract response text (basic JSON parsing)
  if echo "$RESPONSE" | grep -q '"text"'; then
    RESPONSE_TEXT=$(echo "$RESPONSE" | grep -o '"text":"[^"]*' | head -1 | cut -d'"' -f4 | cut -c1-80)
    echo "   ✓ Response: ${RESPONSE_TEXT}..."
    echo "   ⏱️  Latency: ${LATENCY}ms"
  else
    echo "   ⚠️  Response: $RESPONSE"
  fi
  echo ""
  
  # Add 1 second delay between requests to avoid overwhelming Ollama
  [ $i -lt $NUM_REQUESTS ] && sleep 1
done

echo "✅ All test chats created!"
echo ""
echo "📊 To view MLflow experiments:"
echo "   make mlflow-ui"
echo "   Then open http://127.0.0.1:5000"
