---
name: commit
description: git 상태 파악 → 커밋 메시지 생성 → 스테이징 제안. Conventional Commits 형식. 트리거: 커밋, commit, 커밋 메시지 써줘, 뭘 커밋해야 해.
---

# Commit

## 1. 현재 상태 파악

```bash
git status --short
git diff --stat HEAD 2>/dev/null || git diff --stat
```

변경된 파일 목록을 읽고 무슨 작업이 있었는지 파악한다.

## 2. 커밋 단위 결정

변경 파일이 여러 개라면 **논리적으로 묶을 수 있는지** 판단:

- 같은 기능/버그의 파일들 → 하나의 커밋
- 서로 다른 목적의 파일들 → 각각 커밋 (원자 커밋)

원자 커밋이 필요하면 어떤 파일을 어느 커밋에 넣을지 제안한다.

## 3. diff 읽기

```bash
git diff HEAD 2>/dev/null | head -200
# 또는 staged만
git diff --cached | head -200
```

실제 변경 내용을 읽어 커밋 메시지의 본문을 구성한다.

## 4. 커밋 메시지 생성

**형식: Conventional Commits**

```
<type>(<scope>): <subject>

[body — 선택, 왜 변경했는지]
[footer — 선택, BREAKING CHANGE, closes #123]
```

| type | 언제 |
|------|------|
| `feat` | 새 기능 |
| `fix` | 버그 수정 |
| `refactor` | 동작 변화 없는 리팩토링 |
| `docs` | 문서만 |
| `test` | 테스트만 |
| `chore` | 빌드, 설정, 의존성 |
| `perf` | 성능 개선 |

**제목 규칙:**
- 50자 이하
- 동사 원형으로 시작 (add, fix, update, remove — 한국어도 OK)
- 마침표 없음

**예시:**
```
feat(auth): add Google OAuth login flow

Replaces email/password with OAuth to reduce account friction.
Closes #234
```

## 5. 스테이징 + 커밋 명령 출력

```bash
# 단일 커밋
git add <파일들>
git commit -m "$(cat <<'EOF'
<생성된 메시지>
EOF
)"
```

원자 커밋 필요 시 각각의 `git add` + `git commit` 명령 세트를 순서대로 출력.

## 에러 처리

| 상황 | 대응 |
|------|------|
| staged 없음 | `git add` 할 파일 제안 |
| merge conflict 표시 | 커밋 전에 충돌 해결 필요 알림 |
| `.env`, 크리덴셜 파일 포함 | 명시적 경고 + `.gitignore` 추가 제안 |
