---
name: setup
description: Claude Code 로컬 환경 자동 최적화. OS 감지 → settings.json 토큰 삼위일체 적용 → CLAUDE.md 허브 구조 생성 → 스타터 룰 설치 → 결과 리포트. 트리거: setup, 설정해줘, configure, 세팅, 시작.
---

# Setup: Claude Code 환경 자동 최적화

**목표:** 사용자의 로컬 환경을 감지하고, 토큰 효율·워크플로 구조·스타터 룰을 한 번에 설정한다.
**원칙:** 기존 설정을 항상 백업 후 진행. 덮어쓰기 전에 diff를 보여준다.

---

## Phase 1: 환경 감지

```bash
# OS 감지
OS_TYPE=$(uname -s 2>/dev/null || echo "Windows")
echo "OS: $OS_TYPE"

# Claude 설정 경로 결정
if [ "$OS_TYPE" = "Darwin" ] || [ "$OS_TYPE" = "Linux" ]; then
  CLAUDE_DIR="$HOME/.claude"
else
  CLAUDE_DIR="$APPDATA/Claude"
fi
echo "CLAUDE_DIR: $CLAUDE_DIR"

# 기존 설정 확인
echo "=== 기존 settings.json ==="
cat "$CLAUDE_DIR/settings.json" 2>/dev/null || echo "(없음)"

echo "=== 기존 CLAUDE.md ==="
[ -f "$CLAUDE_DIR/CLAUDE.md" ] && echo "EXISTS ($(wc -l < "$CLAUDE_DIR/CLAUDE.md")줄)" || echo "(없음)"

echo "=== 기존 rules/ ==="
ls "$CLAUDE_DIR/rules/" 2>/dev/null || echo "(없음)"

echo "=== 설치된 도구 ==="
which node bun git gh python3 2>/dev/null | sed 's/.*\///' | tr '\n' ' '
echo ""

echo "=== Claude Code 버전 ==="
claude --version 2>/dev/null || echo "(확인 불가)"
```

결과를 읽고 현재 상태를 파악한다. 특히:
- `settings.json`에 이미 `MAX_THINKING_TOKENS`가 있으면 현재 값을 기록
- `CLAUDE.md`가 있으면 내용 확인 (덮어쓰지 않음)
- `rules/` 디렉토리에 파일이 있으면 목록 기록

---

## Phase 2: settings.json 토큰 최적화

**적용 대상:** `$CLAUDE_DIR/settings.json`

기존 파일이 있으면 먼저 백업:
```bash
[ -f "$CLAUDE_DIR/settings.json" ] && cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak" && echo "백업 완료: settings.json.bak"
```

기존 settings.json의 내용을 읽어서 **merge** 방식으로 업데이트한다. 덮어쓰지 말 것.

반드시 포함해야 할 설정:
```json
{
  "model": "sonnet",
  "env": {
    "MAX_THINKING_TOKENS": "10000",
    "CLAUDE_CODE_SUBAGENT_MODEL": "claude-haiku-4-5-20251001",
    "HOOK_PROFILE": "minimal",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
    "SLASH_COMMAND_TOOL_CHAR_BUDGET": "60000",
    "ENABLE_TOOL_SEARCH": "auto:5"
  },
  "permissions": {
    "allow": [
      "Bash(*)", "Read(*)", "Write(*)", "Edit(*)",
      "Glob(*)", "Grep(*)", "WebFetch(*)", "WebSearch(*)",
      "Agent(*)", "mcp__*"
    ],
    "deny": []
  }
}
```

**merge 규칙:**
- 기존 `env` 블록이 있으면 위 키들을 추가/업데이트 (기존 키 유지)
- 기존 `permissions.allow`가 있으면 누락된 항목만 추가
- `model`이 `opus`로 설정돼 있으면 사용자에게 `sonnet`으로 변경할지 물어본다

**토큰 절감 효과를 계산해서 보여준다:**

| 설정 | 변경 전 | 변경 후 | 절감 |
|------|---------|---------|------|
| 메인 모델 | opus | sonnet | ~60% |
| 서브에이전트 | sonnet | haiku | ~80% |
| MAX_THINKING_TOKENS | 31,999 | 10,000 | ~70% |

---

## Phase 3: CLAUDE.md 구조 생성

**자동 결정 (질문하지 않음):**
```bash
# git repo 여부로 프로젝트/글로벌 자동 결정
IS_GIT_REPO=$(git rev-parse --git-dir 2>/dev/null && echo "yes" || echo "no")
if [ "$IS_GIT_REPO" = "yes" ] && [ ! -f "CLAUDE.md" ]; then
  TARGET="project"  # 프로젝트 루트에 생성
  TARGET_PATH="$(git rev-parse --show-toplevel)/CLAUDE.md"
elif [ -f "CLAUDE.md" ]; then
  TARGET="existing"  # 이미 있음, 건드리지 않음
  TARGET_PATH="CLAUDE.md"
else
  TARGET="global"   # git 레포 아님 → 글로벌 설정
  TARGET_PATH="$CLAUDE_DIR/CLAUDE.md"
fi
echo "TARGET: $TARGET → $TARGET_PATH"
```

- `existing`: 파일 내용을 Read하고, @-import 누락 여부만 체크. 수정하지 않음.
- `project` 또는 `global`: 아래 템플릿으로 새 파일 생성.

### CLAUDE.md 허브 템플릿

기존 파일이 없거나 사용자가 새로 만들기를 원하면 생성:

```markdown
# [프로젝트명]

[프로젝트 한 줄 설명]

@./rules/guardrails.md
@./rules/conventions.md

## 스킬 트리거

| 트리거 키워드 | 스킬 | Read 경로 |
|-------------|------|----------|
| 예시: pptx, 슬라이드 | anthropics-pptx | `~/.claude/skills-lib/anthropics-pptx/SKILL.md` |

## 프로젝트 메모

- 기술 스택:
- 주요 경로:
- 주의 사항:
```

**규칙:**
- 20줄 이하 유지
- 룰은 반드시 `@-import`로 분리 (인라인 작성 금지)
- 스킬 트리거 테이블은 자주 쓰는 도메인 스킬만 포함

---

## Phase 3.5: 프로젝트 타입 감지 → 언어별 룰 추가

```bash
# 스택 감지 (중복 가능)
[ -f "package.json" ] && echo "STACK: node"
[ -f "next.config.*" ] || [ -f "next.config.js" ] && echo "STACK: nextjs"
[ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ] && echo "STACK: python"
[ -f "Cargo.toml" ] && echo "STACK: rust"
[ -f "go.mod" ] && echo "STACK: go"
[ -f "*.java" ] 2>/dev/null || [ -d "src/main/java" ] && echo "STACK: java"
```

감지된 스택에 따라 CLAUDE.md에 스택 전용 룰 추가:

| 스택 | 추가할 @-import |
|------|---------------|
| nextjs | `@./rules/nextjs.md` (App Router, Server Components 패턴) |
| python | `@./rules/python.md` (타입 힌트, async, pyproject.toml) |
| rust | `@./rules/rust.md` (borrow checker, Clippy, cargo fmt) |
| go | `@./rules/go.md` (gofmt, error wrapping, context propagation) |

룰 파일이 이 레포의 `rules/lang/` 디렉토리에 없으면 스킵. 없는 스택은 추가 않음.

---

## Phase 4: 스타터 룰 + 훅 설치

아래 파일들을 `$CLAUDE_DIR/rules/`에 복사한다 (이 레포의 `rules/` 디렉토리에서).

```bash
mkdir -p "$CLAUDE_DIR/rules"

# 기존 파일이 없을 때만 복사 (덮어쓰지 않음)
REPO_DIR=$(pwd)  # easy-config-claude 레포 루트
for f in guardrails.md conventions.md; do
  if [ ! -f "$CLAUDE_DIR/rules/$f" ]; then
    cp "$REPO_DIR/rules/$f" "$CLAUDE_DIR/rules/$f"
    echo "설치: rules/$f"
  else
    echo "스킵 (이미 존재): rules/$f"
  fi
done
```

이미 규칙 파일이 있으면 **스킵**한다. 사용자 기존 룰을 침범하지 않는다.

### 훅 스크립트 설치

```bash
mkdir -p "$CLAUDE_DIR/hooks"

# 훅 스크립트 복사 (없을 때만)
for script in easy-session-start.sh easy-stop-summary.sh easy-claude-md-guard.sh; do
  if [ ! -f "$CLAUDE_DIR/hooks/$script" ]; then
    cp "$REPO_DIR/hooks/$script" "$CLAUDE_DIR/hooks/$script"
    chmod +x "$CLAUDE_DIR/hooks/$script"
    echo "설치: hooks/$script"
  fi
done
```

### 메모리 디렉토리 초기화

```bash
mkdir -p "$CLAUDE_DIR/memory"
if [ ! -f "$CLAUDE_DIR/memory/sessions.md" ]; then
  cat > "$CLAUDE_DIR/memory/sessions.md" <<'EOF'
# Session Log
자동 기록. Claude가 이전 세션 컨텍스트가 필요하면 이 파일을 Read한다.

EOF
  echo "생성: memory/sessions.md"
fi
```

### hooks 설정을 settings.json에 병합

기존 `settings.json`에 `hooks` 블록이 없으면 추가:
- `SessionStart` → `easy-session-start.sh`
- `Stop` → `easy-stop-summary.sh`
- `PostToolUse` (matcher: `CLAUDE\.md`) → `easy-claude-md-guard.sh`

이미 `hooks` 블록이 있으면 스킵.

---

## Phase 5: 결과 리포트

설정 완료 후 아래 형식으로 리포트:

```
=== Claude Code 환경 최적화 완료 ===

[ settings.json ]
  ✓ model: sonnet (절감: ~60%)
  ✓ MAX_THINKING_TOKENS: 10000 (절감: ~70%)
  ✓ CLAUDE_CODE_SUBAGENT_MODEL: haiku (절감: ~80%)
  ✓ HOOK_PROFILE: minimal
  ✓ 백업: settings.json.bak

[ CLAUDE.md ]
  ✓ 생성됨: [경로]  /  이미 존재: 수정 없음

[ rules/ ]
  ✓ guardrails.md 설치
  ✓ conventions.md 설치

[ 예상 토큰 절감 ]
  일반 작업 기준: 하루 약 60-80% 비용 절감
  서브에이전트 10회 기준: 약 8배 저렴

=== 다음 단계 ===
1. Claude Code 재시작 (설정 반영)
2. /model sonnet        → 세션 시작 시 모델 확인
3. /cost                → 현재 세션 비용 확인
4. /diagnose            → 설치 후 건강도 점수 확인 (목표: 80점 이상)
5. ~/.claude/skills-lib/ → 필요한 추가 스킬 탐색
```

---

## 에러 핸들링

| 상황 | 대응 |
|------|------|
| `settings.json`이 손상된 JSON | 파싱 실패 알림 후 새 파일로 대체 제안 |
| 권한 오류 (`Permission denied`) | `sudo` 없이 해결 방법 안내 |
| Windows 경로 문제 | PowerShell 명령어로 대체 제공 |
| 기존 `MAX_THINKING_TOKENS`가 이미 최적값 | "이미 최적화됨" 표시 후 다음 단계로 |
| `~/.claude` 디렉토리 없음 | `mkdir -p ~/.claude` 후 진행 |
