#!/usr/bin/env bash
# Test the chat Edge Function (local or deployed).
#
# Usage:
#   export SUPABASE_URL="https://<project>.supabase.co"
#   export SUPABASE_ANON_KEY="<anon-jwt>"
#   export USER_ACCESS_TOKEN="<user JWT from sign-in>"   # not the anon key
#   ./test-request.sh
#
# Local serve:
#   supabase functions serve chat --env-file ../../.env.local
#   export SUPABASE_URL="http://127.0.0.1:54321"
#   ... same USER_ACCESS_TOKEN from your project

set -euo pipefail

: "${SUPABASE_URL:?Set SUPABASE_URL}"
: "${USER_ACCESS_TOKEN:?Set USER_ACCESS_TOKEN (authenticated user JWT)}"

FUNCTION_URL="${FUNCTION_URL:-${SUPABASE_URL}/functions/v1/chat}"

curl -sS -X POST "$FUNCTION_URL" \
  -H "Authorization: Bearer ${USER_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"message":"What patterns do you notice in my journal?"}' \
  | jq .
