#!/bin/bash
# PreToolUse hook: 위험한 파일 편집 차단
# 크리덴셜, git 내부, lock 파일 직접 편집 방지

set -euo pipefail 2>/dev/null || true

INPUT=$(cat 2>/dev/null) || exit 0
[ -z "$INPUT" ] && exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || exit 0
[ -z "$TOOL" ] && exit 0

case "$TOOL" in
  Edit|Write)
    FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
    case "$FILE" in
      */credentials*|*/*secret*|*/.env|*/.env.local|*/.ssh/*|*/.gnupg/*)
        echo "[BLOCKED] 민감한 파일 편집 ($FILE). 사용자에게 먼저 확인하세요." >&2
        exit 2 ;;
      */.git/config|*/.git/HEAD|*/.git/hooks/*)
        echo "[BLOCKED] git 내부 파일 편집 ($FILE). 저장소가 손상될 수 있습니다." >&2
        exit 2 ;;
      */package-lock.json|*/pnpm-lock.yaml|*/yarn.lock|*/bun.lock|*/bun.lockb)
        echo "[BLOCKED] lock 파일은 패키지 매니저가 생성해야 합니다. 직접 편집 금지." >&2
        exit 2 ;;
    esac
    exit 0 ;;
  Bash)
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
    case "$CMD" in
      *"rm -rf /"*|*"rm -rf ~"*|*"rm -rf $HOME"*)
        echo "[BLOCKED] 시스템 전체 삭제 명령 감지." >&2
        exit 2 ;;
      *"git push --force"*|*"git push -f"*)
        echo "[BLOCKED] force push 감지. 의도한 경우 직접 터미널에서 실행하세요." >&2
        exit 2 ;;
    esac
    exit 0 ;;
  *)
    exit 0 ;;
esac
