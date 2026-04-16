#!/bin/bash
# PostToolUse hook: 컨텍스트 잔여량 단계별 경고
# 15% 이하: CRITICAL, 20%: WARNING, 25%: NOTICE, 40%: INFO
set -euo pipefail 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || exit 0
[ -z "$INPUT" ] && exit 0

PCT=$(echo "$INPUT" | jq -r '.session_context_remaining_percent // empty' 2>/dev/null) || exit 0
[ -z "$PCT" ] && exit 0

if [ "$PCT" -le 15 ]; then
  echo "CRITICAL: 컨텍스트 ${PCT}% 남음 — 지금 /compact 실행 안 하면 진행 상황 유실 위험."
elif [ "$PCT" -le 20 ]; then
  echo "WARNING: 컨텍스트 ${PCT}% 남음 — 곧 /compact 필요."
elif [ "$PCT" -le 25 ]; then
  echo "NOTICE: 컨텍스트 ${PCT}% 남음 — 자연스러운 브레이크포인트에서 /compact 권장."
elif [ "$PCT" -le 40 ]; then
  echo "INFO: 컨텍스트 ${PCT}% 남음."
fi

exit 0
