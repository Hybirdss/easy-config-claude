#!/bin/bash
# CLAUDE.md가 20줄을 초과하면 Claude에게 경고 출력
# PostToolUse 훅에서 호출: bash easy-claude-md-guard.sh "$FILE_PATH"

FILE="${1:-CLAUDE.md}"

[ -f "$FILE" ] || exit 0

LINES=$(wc -l < "$FILE")

if [ "$LINES" -gt 20 ]; then
  echo "⚠️  CLAUDE.md가 ${LINES}줄입니다 (권장: 20줄 이하)."
  echo "   룰은 @./rules/*.md로 분리하고 @-import로 연결하세요."
  echo "   현재 인라인 작성된 내용:"
  grep -n "^[^@#-]" "$FILE" | grep -v "^\s*$" | head -10
fi
