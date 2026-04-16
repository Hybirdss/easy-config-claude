---
name: update
description: easy-config-claude 최신 버전으로 업데이트. 사용자 커스텀 설정은 유지하면서 새 rules, hooks, skills만 가져옴. 트리거: update, 업데이트, 최신 버전으로
---

# Update

**목표:** 사용자가 직접 수정한 파일은 건드리지 않는다. 새로 추가된 파일과 업스트림에서 바뀐 파일만 가져온다.

---

## 1. 레포 위치 확인

```bash
# easy-config-claude가 어디 있는지 찾기
REPO_DIR=""

# 방법 1: 현재 디렉토리가 레포인지
[ -f "./skills/setup/SKILL.md" ] && REPO_DIR="$(pwd)"

# 방법 2: 자주 쓰는 위치들
for dir in ~/dev/easy-config-claude ~/easy-config-claude ~/projects/easy-config-claude; do
  [ -f "$dir/skills/setup/SKILL.md" ] && REPO_DIR="$dir" && break
done

echo "REPO_DIR: ${REPO_DIR:-NOT FOUND}"
```

레포를 못 찾으면:
```
❌ easy-config-claude 레포를 찾을 수 없습니다.
   레포 디렉토리에서 실행해주세요: cd ~/dev/easy-config-claude && claude .
```

---

## 2. 최신 버전 가져오기

```bash
cd "$REPO_DIR"

# 현재 로컬 변경사항 확인
git status --short

# upstream에서 최신 가져오기
git fetch origin

# 업데이트 내용 미리 보기
git log HEAD..origin/main --oneline 2>/dev/null || git log HEAD..origin/master --oneline
```

변경사항이 없으면:
```
✅ 이미 최신 버전입니다.
```

---

## 3. 업데이트 적용

```bash
git pull origin main 2>/dev/null || git pull origin master
```

---

## 4. 변경된 파일 분류

```bash
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# 새로 추가된 rules 파일
git diff HEAD~1 --name-only --diff-filter=A -- 'rules/**' 'rules/lang/**'

# 새로 추가된 skills
git diff HEAD~1 --name-only --diff-filter=A -- 'skills/**' 'skills-lib/**'

# 업데이트된 hooks
git diff HEAD~1 --name-only --diff-filter=M -- 'hooks/**'

# settings.json 변경
git diff HEAD~1 -- 'templates/settings.json'
```

---

## 5. 선택적 적용

### 새 rules 파일 → 자동 설치

```bash
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# 업스트림에서 새로 추가된 rules만 설치 (기존 파일 덮어쓰기 금지)
for file in $(git diff HEAD~1 --name-only --diff-filter=A -- 'rules/**'); do
  dest="$CLAUDE_DIR/$file"
  if [ ! -f "$dest" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$REPO_DIR/$file" "$dest"
    echo "✅ 설치됨: $dest"
  else
    echo "⏭️  스킵 (이미 있음): $dest"
  fi
done
```

### 새 skills → 자동 설치

```bash
for skill_dir in $(git diff HEAD~1 --name-only --diff-filter=A -- 'skills/*/SKILL.md' | xargs -I{} dirname {}); do
  dest="$CLAUDE_DIR/$skill_dir"
  if [ ! -d "$dest" ]; then
    mkdir -p "$dest"
    cp "$REPO_DIR/$skill_dir/SKILL.md" "$dest/SKILL.md"
    echo "✅ 설치됨: $dest"
  else
    echo "⏭️  스킵 (이미 있음): $dest"
  fi
done
```

### 업데이트된 hooks → 사용자 확인 후 적용

훅은 사용자가 직접 수정했을 수 있으므로 덮어쓰기 전에 diff 보여주기:

```bash
for hook in $(git diff HEAD~1 --name-only --diff-filter=M -- 'hooks/**'); do
  hook_name=$(basename "$hook")
  dest="$CLAUDE_DIR/hooks/$hook_name"

  if [ -f "$dest" ]; then
    echo "\n📝 훅 변경됨: $hook_name"
    diff "$dest" "$REPO_DIR/$hook"
    echo "이 훅을 업데이트하시겠습니까? [y/N]"
    # 사용자 응답 대기
  else
    cp "$REPO_DIR/$hook" "$dest"
    echo "✅ 새 훅 설치됨: $dest"
  fi
done
```

### settings.json 변경 → merge

```bash
SETTINGS="$CLAUDE_DIR/settings.json"

if git diff HEAD~1 --name-only -- 'templates/settings.json' | grep -q .; then
  echo "\n⚙️  settings.json 업데이트 있음:"
  git diff HEAD~1 -- 'templates/settings.json'

  # 새 키만 추가 (기존 사용자 설정 보존)
  python3 - <<'EOF'
import json, os

claude_dir = os.path.expanduser(os.environ.get('CLAUDE_CONFIG_DIR', '~/.claude'))
settings_path = f"{claude_dir}/settings.json"
template_path = "templates/settings.json"

with open(settings_path) as f:
    current = json.load(f)
with open(template_path) as f:
    template = json.load(f)

# 깊은 merge: template에만 있는 키를 current에 추가
def deep_merge_new_only(base, new):
    for k, v in new.items():
        if k not in base:
            base[k] = v
            print(f"  ✅ 추가됨: {k} = {v}")
        elif isinstance(v, dict) and isinstance(base[k], dict):
            deep_merge_new_only(base[k], v)

deep_merge_new_only(current, template)

with open(settings_path, 'w') as f:
    json.dump(current, f, indent=2)
print("settings.json 업데이트 완료")
EOF
fi
```

---

## 6. 결과 리포트

```
========================================
easy-config-claude 업데이트 완료
========================================

📥 적용된 변경사항:
  ✅ rules/lang/nextjs.md 새로 설치
  ✅ skills/techdebt/SKILL.md 새로 설치
  ✅ hooks/context-monitor.sh 업데이트 (확인 후 적용)

⏭️  스킵된 항목:
  • rules/intelligence.md (이미 있음, 덮어쓰기 안 함)

⚙️  settings.json:
  ✅ ENABLE_TOOL_SEARCH: auto:5 추가됨

최신 버전: v[커밋 해시]
다음 업데이트 확인: 2주 후 (또는 'update' 다시 실행)
========================================
```

---

## 주의

- **사용자가 직접 수정한 파일은 절대 덮어쓰지 않는다.**
- 훅처럼 동작에 영향을 주는 파일은 diff 보여주고 확인받는다.
- `settings.json`은 새 키만 추가하고 기존 값 변경 안 한다.
