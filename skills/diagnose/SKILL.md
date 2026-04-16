---
name: diagnose
description: Claude Code 세팅 건강도를 0-100점으로 진단. settings.json 최적화 여부, CLAUDE.md 구조, rules 파일, 훅 스크립트, MCP 개수, 메모리 시스템을 체크하고 구체적인 수정 방법을 알려줌. 트리거: diagnose, 진단, 건강 체크, 내 세팅 어때, score.
---

# Diagnose: Claude Code 세팅 건강도 체크

**목표:** 현재 `~/.claude/` 환경을 5개 카테고리로 채점하고, 각 항목의 문제와 수정 방법을 구체적으로 알려준다.

---

## 채점 기준 (총 100점)

| 카테고리 | 배점 | 체크 항목 |
|---------|------|----------|
| A. Settings 최적화 | 30점 | 토큰 삼위일체, 모델 설정 |
| B. CLAUDE.md 구조 | 25점 | 라인 수, @-import 분리 여부 |
| C. Rules 파일 | 15점 | guardrails, conventions 존재 여부 |
| D. Hooks 시스템 | 20점 | 훅 스크립트 존재, 프로파일 설정 |
| E. 메모리 시스템 | 10점 | sessions.md, memory/ 디렉토리 |

---

## 진단 실행

### A. Settings 최적화 (30점)

```bash
CLAUDE_DIR="${HOME}/.claude"
python3 - <<'PYEOF'
import json, os, sys

claude_dir = os.path.expanduser("~/.claude")
settings_path = os.path.join(claude_dir, "settings.json")

score = 0
issues = []
goods = []

try:
    with open(settings_path) as f:
        s = json.load(f)
except FileNotFoundError:
    print("SCORE_A: 0/30")
    print("ISSUE: settings.json 없음 — /setup 실행 필요")
    sys.exit(0)
except json.JSONDecodeError:
    print("SCORE_A: 0/30")
    print("ISSUE: settings.json 손상됨 — 백업 후 재생성 필요")
    sys.exit(0)

env = s.get("env", {})

# 메인 모델 (10점)
model = s.get("model", "")
if model == "sonnet":
    score += 10
    goods.append("model: sonnet ✓")
elif model == "opus":
    issues.append("model이 opus — sonnet으로 변경 시 ~60% 절감")
elif model == "haiku":
    score += 5
    issues.append("model이 haiku — 복잡한 작업엔 sonnet 권장")
else:
    issues.append(f"model 미설정 또는 unknown: '{model}'")

# MAX_THINKING_TOKENS (10점)
mtt = env.get("MAX_THINKING_TOKENS", "")
if mtt == "10000":
    score += 10
    goods.append("MAX_THINKING_TOKENS: 10000 ✓")
elif mtt == "0":
    score += 8
    goods.append("MAX_THINKING_TOKENS: 0 (비활성화, 단순 작업에 적합)")
elif mtt and int(mtt) < 15000:
    score += 7
    issues.append(f"MAX_THINKING_TOKENS: {mtt} — 10000이 최적값")
elif not mtt:
    issues.append("MAX_THINKING_TOKENS 미설정 — 기본값 31999 사용 중 (낭비)")
else:
    issues.append(f"MAX_THINKING_TOKENS: {mtt} — 10000으로 낮추면 ~70% 절감")

# CLAUDE_CODE_SUBAGENT_MODEL (10점)
sam = env.get("CLAUDE_CODE_SUBAGENT_MODEL", "")
if "haiku" in sam:
    score += 10
    goods.append(f"CLAUDE_CODE_SUBAGENT_MODEL: haiku ✓")
elif not sam:
    issues.append("CLAUDE_CODE_SUBAGENT_MODEL 미설정 — 서브에이전트가 메인 모델 사용 중")
else:
    issues.append(f"CLAUDE_CODE_SUBAGENT_MODEL: {sam} — haiku로 변경 시 ~80% 절감")

print(f"SCORE_A: {score}/30")
for g in goods:
    print(f"  ✓ {g}")
for i in issues:
    print(f"  ✗ {i}")
PYEOF
```

### B. CLAUDE.md 구조 (25점)

```bash
python3 - <<'PYEOF'
import os, re

claude_dir = os.path.expanduser("~/.claude")
f_path = os.path.join(claude_dir, "CLAUDE.md")

score = 0
issues = []
goods = []

if not os.path.exists(f_path):
    # 프로젝트 CLAUDE.md 확인
    local = "CLAUDE.md"
    if os.path.exists(local):
        f_path = local
    else:
        print("SCORE_B: 0/25")
        print("  ✗ CLAUDE.md 없음 — /setup으로 생성 필요")
        import sys; sys.exit(0)

with open(f_path) as f:
    lines = f.readlines()

total_lines = len(lines)
import_lines = [l for l in lines if l.strip().startswith("@")]
inline_rule_lines = [l for l in lines if len(l.strip()) > 80 and not l.strip().startswith("#") and not l.strip().startswith("@")]

# 라인 수 (10점)
if total_lines <= 20:
    score += 10
    goods.append(f"CLAUDE.md {total_lines}줄 (20줄 이하) ✓")
elif total_lines <= 40:
    score += 6
    issues.append(f"CLAUDE.md {total_lines}줄 — 20줄 이하 권장 (현재 {total_lines-20}줄 초과)")
elif total_lines <= 80:
    score += 3
    issues.append(f"CLAUDE.md {total_lines}줄 — 대부분의 내용을 rules/*.md로 분리해야 함")
else:
    issues.append(f"CLAUDE.md {total_lines}줄 — 심각한 블로트. 매 요청마다 ~{total_lines*4}토큰 낭비")

# @-import 사용 (10점)
if len(import_lines) >= 2:
    score += 10
    goods.append(f"@-import {len(import_lines)}개 사용 ✓")
elif len(import_lines) == 1:
    score += 5
    issues.append("@-import 1개만 있음 — guardrails, conventions 최소 2개 import 권장")
else:
    issues.append("@-import 없음 — 모든 룰이 인라인 작성됨 (분리 필요)")

# 인라인 룰 없음 (5점)
if len(inline_rule_lines) == 0:
    score += 5
    goods.append("인라인 룰 없음 (깔끔한 허브 구조) ✓")
else:
    issues.append(f"인라인 룰 {len(inline_rule_lines)}줄 감지 — rules/*.md로 분리 권장")

print(f"SCORE_B: {score}/25")
for g in goods:
    print(f"  ✓ {g}")
for i in issues:
    print(f"  ✗ {i}")
PYEOF
```

### C. Rules 파일 (15점)

```bash
python3 - <<'PYEOF'
import os

claude_dir = os.path.expanduser("~/.claude")
rules_dir = os.path.join(claude_dir, "rules")

score = 0
issues = []
goods = []

if not os.path.isdir(rules_dir):
    print("SCORE_C: 0/15")
    print("  ✗ rules/ 디렉토리 없음 — /setup으로 생성 필요")
    import sys; sys.exit(0)

files = os.listdir(rules_dir)

essential = {"guardrails.md": 6, "conventions.md": 5}
for fname, pts in essential.items():
    if fname in files:
        score += pts
        goods.append(f"{fname} ✓")
    else:
        issues.append(f"{fname} 없음 (/{fname} 설치 필요)")

# 보너스: 추가 룰 파일
extra = [f for f in files if f not in essential and f.endswith(".md")]
if extra:
    score += min(len(extra) * 2, 4)
    goods.append(f"추가 룰 파일 {len(extra)}개: {', '.join(extra)}")

score = min(score, 15)
print(f"SCORE_C: {score}/15")
for g in goods:
    print(f"  ✓ {g}")
for i in issues:
    print(f"  ✗ {i}")
PYEOF
```

### D. Hooks 시스템 (20점)

```bash
python3 - <<'PYEOF'
import os, json

claude_dir = os.path.expanduser("~/.claude")
hooks_dir = os.path.join(claude_dir, "hooks")
settings_path = os.path.join(claude_dir, "settings.json")

score = 0
issues = []
goods = []

# HOOK_PROFILE 설정 (5점)
try:
    with open(settings_path) as f:
        s = json.load(f)
    hp = s.get("env", {}).get("HOOK_PROFILE", "")
    if hp in ("minimal", "standard", "strict"):
        score += 5
        goods.append(f"HOOK_PROFILE: {hp} ✓")
    else:
        issues.append("HOOK_PROFILE 미설정 — minimal/standard/strict 중 하나 권장")
except:
    issues.append("settings.json 읽기 실패")

# hooks.json 존재 (5점)
hooks_json = os.path.join(claude_dir, "hooks", "hooks.json")
if os.path.exists(hooks_json):
    try:
        with open(hooks_json) as f:
            hooks = json.load(f)
        score += 5
        goods.append(f"hooks.json 존재 ({len(hooks)}개 훅 정의) ✓")
    except:
        issues.append("hooks.json 파싱 실패")
else:
    # settings.json 내부 hooks 확인
    try:
        with open(settings_path) as f:
            s = json.load(f)
        if s.get("hooks"):
            score += 5
            goods.append("settings.json 내 hooks 설정 존재 ✓")
        else:
            issues.append("훅 정의 없음 — 세션 추적, CLAUDE.md 가드 등 미작동")
    except:
        issues.append("훅 정의 없음")

# 훅 스크립트 파일 존재 (10점)
if os.path.isdir(hooks_dir):
    scripts = [f for f in os.listdir(hooks_dir) if f.endswith(".sh") or f.endswith(".py") or f.endswith(".js")]
    if len(scripts) >= 3:
        score += 10
        goods.append(f"훅 스크립트 {len(scripts)}개 존재 ✓")
    elif len(scripts) > 0:
        score += 5
        issues.append(f"훅 스크립트 {len(scripts)}개 — session-start, stop-summary, claude-md-guard 3개 권장")
    else:
        issues.append("hooks/ 디렉토리는 있지만 스크립트 없음")
else:
    issues.append("hooks/ 디렉토리 없음 — easy-config-claude hooks/ 복사 필요")

print(f"SCORE_D: {score}/20")
for g in goods:
    print(f"  ✓ {g}")
for i in issues:
    print(f"  ✗ {i}")
PYEOF
```

### E. 메모리 시스템 (10점)

```bash
python3 - <<'PYEOF'
import os

claude_dir = os.path.expanduser("~/.claude")
memory_dir = os.path.join(claude_dir, "memory")

score = 0
issues = []
goods = []

if os.path.isdir(memory_dir):
    files = os.listdir(memory_dir)
    if "sessions.md" in files:
        sessions_path = os.path.join(memory_dir, "sessions.md")
        with open(sessions_path) as f:
            lines = f.readlines()
        session_count = len([l for l in lines if l.startswith("- 20")])
        score += 6
        goods.append(f"sessions.md 존재 ({session_count}개 세션 기록) ✓")
    else:
        issues.append("sessions.md 없음 — stop-summary 훅이 자동 생성")

    if "MEMORY.md" in files:
        score += 4
        goods.append("MEMORY.md (메모리 인덱스) ✓")
    else:
        issues.append("MEMORY.md 없음 — 메모리 인덱스 파일 권장")
else:
    issues.append("memory/ 디렉토리 없음 — 세션 간 컨텍스트 유실")

print(f"SCORE_E: {score}/10")
for g in goods:
    print(f"  ✓ {g}")
for i in issues:
    print(f"  ✗ {i}")
PYEOF
```

---

## 최종 리포트 생성

위 5개 섹션의 점수를 합산하고 아래 형식으로 출력:

```
╔══════════════════════════════════════╗
║   Claude Code 세팅 건강도 진단 결과   ║
╚══════════════════════════════════════╝

A. Settings 최적화    [XX/30] ████████░░
B. CLAUDE.md 구조     [XX/25] ███████░░░
C. Rules 파일         [XX/15] █████░░░░░
D. Hooks 시스템       [XX/20] ████░░░░░░
E. 메모리 시스템      [XX/10] ███░░░░░░░

총점: XX/100  →  등급: [A/B/C/D/F]

등급 기준:
  A (90-100): 프로덕션 레벨
  B (70-89):  잘 설정됨, 소소한 개선 가능
  C (50-69):  기본 구조 있음, 중요한 갭 존재
  D (30-49):  토큰 낭비 중. 즉시 개선 필요
  F (0-29):   미설정 상태. /setup 실행 권장

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

즉시 수정할 것 (우선순위 순):
1. [가장 높은 점수 갭 항목]
2. [두 번째]
3. [세 번째]

수정 명령:
  /setup    → 전체 재설정
  /setup tokens  → settings.json만
  /setup rules   → rules/만
  /setup hooks   → hooks/만
```

프로그레스 바 계산: `score/max * 10`개의 `█`, 나머지는 `░`
