#!/bin/bash
# 세션 종료 시 1줄 요약을 ~/.claude/memory/sessions.md에 기록
# Claude가 Stop 직전에 CLAUDE_SESSION_SUMMARY 환경변수에 요약을 넣으면 그걸 씀
# 없으면 날짜+디렉토리만 기록

MEMORY_DIR="$HOME/.claude/memory"
SESSIONS_FILE="$MEMORY_DIR/sessions.md"
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"

mkdir -p "$MEMORY_DIR"

# 세션 시간 계산
START_FILE="/tmp/claude-session-start-${SESSION_ID}"
DURATION=""
if [ -f "$START_FILE" ]; then
  START=$(cat "$START_FILE")
  END=$(date +%s)
  SECS=$(( END - START ))
  MINS=$(( SECS / 60 ))
  DURATION="${MINS}m"
  rm -f "$START_FILE"
fi

DATE=$(date '+%Y-%m-%d %H:%M')
PWD_SHORT=$(basename "$PWD")
SUMMARY="${CLAUDE_SESSION_SUMMARY:-작업 내용 없음}"

# MEMORY.md 인덱스가 없으면 초기화
if [ ! -f "$SESSIONS_FILE" ]; then
  cat > "$SESSIONS_FILE" <<'EOF'
# Session Log
자동 기록. Claude가 이전 세션 컨텍스트가 필요하면 이 파일을 Read한다.

EOF
fi

echo "- $DATE | $PWD_SHORT | ${DURATION} | $SUMMARY" >> "$SESSIONS_FILE"

# 최근 30줄만 유지 (파일 무한 증가 방지)
LINES=$(wc -l < "$SESSIONS_FILE")
if [ "$LINES" -gt 50 ]; then
  # 헤더(4줄) + 최근 30줄 유지
  head -4 "$SESSIONS_FILE" > "/tmp/sessions-trim.md"
  tail -30 "$SESSIONS_FILE" >> "/tmp/sessions-trim.md"
  mv "/tmp/sessions-trim.md" "$SESSIONS_FILE"
fi
