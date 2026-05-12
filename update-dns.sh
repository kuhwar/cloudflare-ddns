#!/bin/bash

# ─── CONFIG ───────────────────────────────────────────────────────────────────
SLEEP_INTERVAL="${SLEEP_INTERVAL:-300}"
EXTERNAL_IP="0.0.0.0"
# ──────────────────────────────────────────────────────────────────────────────

while true; do
  echo "────────────────────────────────────────────"
  echo "🕐 $(date '+%Y-%m-%d %H:%M:%S') — Starting DNS check..."
  echo "────────────────────────────────────────────"

  # Step 1 — Get external IP
  echo "🌐 Fetching external IP..."
  NEW_EXTERNAL_IP=$(curl -s ifconfig.me)

  if [ -z "$NEW_EXTERNAL_IP" ]; then
    echo "❌ Failed to fetch external IP."
    echo "⏳ Retrying in $SLEEP_INTERVAL seconds..."
    sleep $SLEEP_INTERVAL
    continue
  fi
    
  if [ "$NEW_EXTERNAL_IP" = "$EXTERNAL_IP" ]; then
    echo "🌐 External IP: $NEW_EXTERNAL_IP No IP change detected."
    sleep $SLEEP_INTERVAL
    continue
  fi

  EXTERNAL_IP=$NEW_EXTERNAL_IP
  echo "🌐 Setting DNS to: $EXTERNAL_IP."
  
  # Step 2 — Get Zone ID
  echo "🔍 Fetching Zone ID for $ZONE_NAME..."
  ZONE_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE_NAME" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json")

  ZONE_ID=$(echo $ZONE_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

  if [ -z "$ZONE_ID" ]; then
    echo "❌ Failed to get Zone ID. Check your API token and zone name."
    echo "⏳ Retrying in $SLEEP_INTERVAL seconds..."
    sleep $SLEEP_INTERVAL
    continue
  fi
  echo "✅ Zone ID: $ZONE_ID"

  # Step 3 — Get Record ID and current IP
  echo "🔍 Fetching DNS record for $RECORD_NAME..."
  RECORD_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$RECORD_NAME" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json")

  RECORD_ID=$(echo $RECORD_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  CURRENT_DNS_IP=$(echo $RECORD_RESPONSE | grep -o '"content":"[^"]*' | head -1 | cut -d'"' -f4)

  if [ -z "$RECORD_ID" ]; then
    echo "❌ Failed to get Record ID. Check the record name."
    echo "⏳ Retrying in $SLEEP_INTERVAL seconds..."
    sleep $SLEEP_INTERVAL
    continue
  fi
  echo "✅ Record ID: $RECORD_ID"
  echo "📡 Current DNS IP: $CURRENT_DNS_IP"

  # Step 4 — Compare and update if different
  if [ "$EXTERNAL_IP" = "$CURRENT_DNS_IP" ]; then
    echo "✅ DNS is already up to date. No changes needed."
  else
    echo "🔄 IP has changed ($CURRENT_DNS_IP → $EXTERNAL_IP). Updating DNS record..."
    UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json" \
      --data "{
        \"type\": \"A\",
        \"name\": \"$RECORD_NAME\",
        \"content\": \"$EXTERNAL_IP\",
        \"ttl\": 120,
        \"proxied\": false
      }")

    SUCCESS=$(echo $UPDATE_RESPONSE | grep -o '"success":[^,]*' | cut -d':' -f2)

    if [ "$SUCCESS" = "true" ]; then
      echo "✅ DNS updated successfully: $RECORD_NAME → $EXTERNAL_IP"
    else
      echo "❌ Update failed. Response: $UPDATE_RESPONSE"
    fi
  fi

  echo "⏳ Sleeping for $SLEEP_INTERVAL seconds..."
  sleep $SLEEP_INTERVAL

done