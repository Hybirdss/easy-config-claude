#!/bin/bash
# 세션 시작 시간 기록 — cost-tracker와 session summary에서 참조
SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
date +%s > "/tmp/claude-session-start-${SESSION_ID}"
