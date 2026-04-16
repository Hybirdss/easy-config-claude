#!/bin/bash
# Stop hook: Claude가 작업을 마치면 데스크톱 알림
# end_turn에만 발동 (중간 도구 호출 때는 무음)

INPUT=$(cat 2>/dev/null) || exit 0
[ -z "$INPUT" ] && exit 0

STOP_REASON=$(echo "$INPUT" | jq -r '.stop_reason // "done"' 2>/dev/null)

if [ "$STOP_REASON" = "end_turn" ]; then
  IS_HOOK=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
  [ "$IS_HOOK" = "true" ] && exit 0

  # Linux: notify-send / macOS: osascript
  if command -v notify-send &>/dev/null; then
    notify-send -u normal -t 5000 -i terminal "Claude Code" "작업 완료" 2>/dev/null || true
  elif command -v osascript &>/dev/null; then
    osascript -e 'display notification "작업 완료" with title "Claude Code"' 2>/dev/null || true
  fi
fi

exit 0
