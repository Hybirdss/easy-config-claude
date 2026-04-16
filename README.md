# easy-config-claude

> Claude Code를 처음 쓰는데 뭔가 이상하다고 느끼는 사람들을 위해 만들었습니다.

Claude Code 쓰다가 이런 생각 든 적 없나요?

- *"분명 별거 안 했는데 토큰이 왜 이렇게 날아갔지?"*
- *"이 API 왜 느리냐고 했더니 '캐싱을 고려해볼 수 있습니다'만 세 번..."*
- *"틀린 코드 짠 것 같은데 Claude가 '좋은 접근이에요!'라고 해버림"*

이 레포는 그 문제를 전부 고칩니다. 클론하고 "설정해줘" 한 마디면 끝입니다.

```bash
git clone https://github.com/Hybirdss/easy-config-claude
cd easy-config-claude
claude .
```

```
설정해줘
```

OS 자동 감지, 기존 설정 백업, 최적값 적용. 5분이면 세팅 완료입니다.

---

## Claude 답변이 이렇게 달라집니다

intelligence rules가 설치되면 Claude가 다르게 대답합니다. 설치 전후로 같은 질문을 해보시면 바로 체감됩니다.

**[비용 절감] 전:**
```
사용자: 이 API 왜 이렇게 느려요?

Claude: API 성능을 개선하는 방법을 몇 가지 고려해볼 수 있습니다.
        캐싱 레이어를 추가하거나, 데이터베이스 쿼리를 최적화하거나,
        CDN 활용을 검토해볼 수도 있습니다...
```

**[비용 절감] 후:**
```
사용자: 이 API 왜 이렇게 느려요?

Claude: getUserPosts() 평균 870ms (p95: 2.1s).
        원인: routes/users.ts:47 루프 안에서 DB 쿼리 N+1.
        유저 1명당 쿼리 23번 발생 중.

        수정: 쿼리 1개로 JOIN — 예상 응답시간 90ms.

        diff:
        - users.forEach(u => u.posts = await getPosts(u.id))
        + const posts = await getPostsByUserIds(users.map(u => u.id))
```

**[정직한 피드백] 전:**
```
사용자: 이렇게 짜면 되겠죠?

Claude: 네, 좋은 접근방식이에요! 다만 몇 가지
        추가로 고려하면 더 좋을 것 같습니다...
```

**[정직한 피드백] 후:**
```
사용자: 이렇게 짜면 되겠죠?

Claude: 아니요. race condition 있습니다.
        두 요청이 동시에 오면 카운터가 어긋납니다.
        atomic operation 또는 mutex 필요합니다.
```

측정값, 파일 경로, 줄 번호로 말하게 됩니다. "고려해볼 수 있어요"는 차단됩니다.

---

## 매일 쓰는 것

### `커밋` — commit message 자동 생성

```
커밋
```

```
[git status + diff 분석]

커밋 메시지:

  feat(auth): add rate limiting to login endpoint

  Prevents brute force. 5 attempts/min per IP.
  Returns 429 with Retry-After header.
  Closes #234

스테이징:
  git add src/middleware/rateLimit.ts src/routes/auth.ts
  git commit -m "..."

⚠️  .env.local 감지됨 — 스테이징에서 제외됨
```

`git commit -m "fix stuff"` 시절은 끝입니다.

---

### `코드 리뷰` — diff 기반 리뷰

```
코드 리뷰
```

```
## 코드 리뷰 결과

### CRITICAL
- src/api/users.ts:134  파라미터를 SQL에 직접 삽입 중 — SQL injection
  현재: db.query(`SELECT * FROM users WHERE id = ${userId}`)
  수정: db.query('SELECT * FROM users WHERE id = ?', [userId])

### HIGH
- src/hooks/useData.ts:23  useEffect 의존성 배열 누락
  → [userId, refresh] 추가 필요

### MEDIUM
- src/utils/format.ts:8  빈 문자열 입력 처리 없음

총 이슈: CRITICAL 1 / HIGH 1 / MEDIUM 1
머지 판단: CRITICAL 해결 후 머지
```

"LGTM" 날리다가 프로덕션에서 터지는 일이 줄어듭니다.

---

### `진단` — 설치 후 건강도 체크

```
진단
```

```
╔══════════════════════════════════════╗
║   Claude Code 세팅 건강도 진단 결과   ║
╚══════════════════════════════════════╝

A. Settings 최적화    [28/30] █████████░
B. CLAUDE.md 구조     [25/25] ██████████
C. Rules 파일         [15/15] ██████████
D. Hooks 시스템       [18/20] █████████░
E. 메모리 시스템      [ 6/10] ██████░░░░

총점: 92/100  →  등급: A

즉시 수정할 것:
1. memory/MEMORY.md 없음 — mkdir ~/.claude/memory && touch ~/.claude/memory/MEMORY.md
2. HOOK_PROFILE standard → minimal 다운그레이드 권장 (훅 오버헤드)
```

점수가 낮으면 뭐가 문제인지, 어떻게 고치는지 딱 알려줍니다.

---

## 무엇이 바뀌는가

### `~/.claude/settings.json`

기존 파일은 `.bak`으로 백업됩니다. 아래 값만 merge합니다:

| 설정 | 기본값 | 변경 후 | 효과 |
|------|--------|---------|------|
| `model` | opus | **sonnet** | ~60% 절감 |
| `MAX_THINKING_TOKENS` | 31,999 | **10,000** | ~70% 절감 |
| `ENABLE_TOOL_SEARCH` | 전부 로드 | **auto:5** | 툴 지연 로드, 컨텍스트 절약 |
| `SLASH_COMMAND_TOOL_CHAR_BUDGET` | 기본 | **60,000** | 스킬 컨텍스트 예산 확보 |

### `~/.claude/rules/` — Claude 행동 규칙 4개

| 파일 | 핵심 내용 |
|------|----------|
| `guardrails.md` | "완료"라고 말하려면 출력 보여줄 것. hedging 금지. |
| `conventions.md` | 만들기 전에 검색. 구 코드 삭제. 서브에이전트 활용. |
| `model-routing.md` | 설계·반복실패 → Opus 자동 제안. 기본은 Sonnet. |
| `intelligence.md` | **← 이게 핵심.** Anti-slop. Anti-sycophancy. Boil the lake. |

### `~/.claude/hooks/` — 7개 자동화

| 훅 | 언제 | 동작 |
|----|------|------|
| `failure-dna.py` | 도구 실패 | 같은 에러 2회 → 이전 실패 기록 주입. 루프 차단. |
| `context-monitor.sh` | 매 응답 후 | 40/25/20/15% 단계별 경고. 15%에서 강제 알림. |
| `block-dangerous.sh` | 실행 전 | force push, 크리덴셜 파일, lock 파일 직접 편집 차단. |
| `notify-done.sh` | 작업 완료 | 데스크톱 알림 (end_turn만, 중간 호출엔 무음). |
| `easy-stop-summary.sh` | 세션 종료 | `~/.claude/memory/sessions.md`에 1줄 자동 기록. |
| `easy-claude-md-guard.sh` | CLAUDE.md 수정 | 20줄 초과 시 경고 + 인라인 룰 위치 알림. |
| `easy-session-start.sh` | 세션 시작 | 시간 기록 (비용 추적용). |

---

## 키워드로 자동 켜지는 것들

평소엔 컨텍스트를 차지하지 않습니다. 말하는 순간 Claude가 해당 모드로 진입합니다.

| 말하면 | 동작 |
|-------|------|
| `아이디어 있어`, `이거 만들만해?`, `기획 검토` | YC 스타일 6개 질문으로 아이디어 검증. |
| `Gmail`, `구글 캘린더`, `Drive`, `스프레드시트` | Google Workspace 자동화 (`gws` 바이너리 필요). |
| `런북`, `SOP`, `플레이북`, `온보딩 문서` | 실제로 쓰이는 구조의 런북 작성. |

---

## Failure DNA가 뭔가요?

같은 에러가 2번 나오면 이런 메시지가 나옵니다:

```
[Failure DNA] 이 에러 패턴 3번째 반복 (tool: Bash)
이전 실패: Cannot find module 'react/jsx-runtime' — peerDeps 불일치
다른 접근법을 시도하거나 Opus로 전환하세요 (/model opus)
```

Claude가 같은 디버깅 루프를 3번 도는 걸 막습니다. 에러 핑거프린트를 `~/.claude/failure-dna/`에 저장해서 세션 간에도 기억합니다.

---

## 파일 구조

```
easy-config-claude/
├── CLAUDE.md                    허브 (25줄)
├── rules/
│   ├── guardrails.md            검증·자율성·에스컬레이션
│   ├── conventions.md           코드 컨벤션·컨텍스트 관리
│   ├── model-routing.md         Opus 자동 전환 규칙
│   └── intelligence.md          ← 이게 핵심. Claude를 다르게 만드는 규칙
├── skills/                      매일 쓰는 것 (슬래시 커맨드)
│   ├── commit/SKILL.md          커밋 메시지 생성
│   ├── review/SKILL.md          코드 리뷰
│   ├── setup/SKILL.md           환경 자동 설정
│   └── diagnose/SKILL.md        세팅 건강도 채점
├── skills-lib/                  상황별 (키워드로 자동 로드)
│   ├── gstack/SKILL.md          아이디어 검증 · 플랜 리뷰
│   ├── gws/SKILL.md             Google Workspace 자동화
│   └── second-brain/SKILL.md    런북 · SOP · 지식 관리
├── hooks/                       7개 자동화 스크립트
└── templates/settings.json      설정 템플릿
```

---

## Q&A

**기존 settings.json 날아가나요?**
안 날아갑니다. `settings.json.bak`으로 백업 후 없는 항목만 추가합니다. 걱정하지 않아도 됩니다.

**이미 Claude Code 쓰고 있는데 써도 되나요?**
됩니다. 기존 설정을 건드리지 않고 빠진 것만 채웁니다. 지금 세팅에 레이어를 얹는 방식입니다.

**Mac이랑 Windows도 되나요?**
됩니다. 설치 시 OS 자동 감지합니다. macOS / Linux / Windows(WSL) 모두 테스트됐습니다.

**Sonnet이 Opus보다 못하지 않나요?**
일반 코딩·리뷰·테스트의 80%는 Sonnet으로 충분합니다. 설계나 복잡한 디버깅에서 막히면 그때 `/model opus`로 전환하면 됩니다. 그게 하루 비용을 60% 줄이는 방법입니다.

**intelligence.md가 실제로 차이를 만드나요?**
네. Claude는 기본적으로 hedging 하도록 훈련돼 있습니다. `intelligence.md`는 그 경향을 명시적으로 억제합니다. 가장 빠르게 체감하는 방법: 설치 전후로 같은 질문을 해보세요.

**설치하다가 막히면요?**
[Issues](https://github.com/Hybirdss/easy-config-claude/issues)에 올려주세요. 같이 해결합니다.

---

## 더 파고들고 싶다면

이 레포를 만들면서 참고한 원조들과, Claude Code를 제대로 쓰려면 알아두면 좋은 자료들입니다.

### Claude Code 세팅 & 스킬

| 레포 | 별점 | 설명 |
|------|------|------|
| [everything-claude-code](https://github.com/affaan-m/everything-claude-code) | ⭐ 원조 | 156개 스킬, 38개 에이전트. 이 레포가 가장 많이 참고한 곳 |
| [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | 큐레이션 | 커뮤니티가 만든 스킬·훅·CLAUDE.md 모음. 찾는 게 있으면 여기 |

### MCP 서버 (Claude 기능 확장)

MCP(Model Context Protocol)는 Claude에 새로운 도구를 붙이는 방법입니다. DB 조회, 파일 시스템, 외부 API를 Claude가 직접 쓸 수 있게 됩니다.

| 레포 | 설명 |
|------|------|
| [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) | Anthropic 공식 MCP 서버 모음. filesystem, GitHub, Slack, Postgres 등 |
| [punkpeye/awesome-mcp-servers](https://github.com/punkpeye/awesome-mcp-servers) | 커뮤니티가 만든 MCP 서버 큐레이션. 200개+ |
| [wong2/awesome-mcp-servers](https://github.com/wong2/awesome-mcp-servers) | MCP 서버 또 다른 큐레이션. 검색하기 좋게 정리돼 있음 |

### Anthropic 공식 학습 자료

| 레포 | 설명 |
|------|------|
| [anthropics/anthropic-cookbook](https://github.com/anthropics/anthropic-cookbook) | Anthropic 공식 레시피 모음. RAG, 에이전트, 툴 사용 예제 전부 있음 |
| [anthropics/courses](https://github.com/anthropics/courses) | 공식 강의 노트북. Prompt Engineering부터 Tool Use까지 |
| [Claude Code 공식 문서](https://docs.anthropic.com/ko/docs/claude-code) | 훅, 커스텀 커맨드, 메모리 시스템 공식 레퍼런스 |

### Claude Code IDE 플러그인

터미널 외에 에디터 안에서도 Claude Code를 쓸 수 있습니다.

| 플러그인 | 에디터 | 설명 |
|---------|--------|------|
| [Claude Code for VS Code](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code) | VS Code | 공식 확장. 터미널 Claude Code와 동일한 기능을 에디터 패널에서 |
| [Claude Code for JetBrains](https://plugins.jetbrains.com/plugin/26071-claude-code) | IntelliJ / WebStorm 등 | 공식 플러그인. 코드 선택 → 즉시 Claude에게 물어보기 |

### 이 레포에 포함된 워크플로 도구

설치 시 함께 세팅되는 skills-lib 도구들 — 필요한 사람은 더 파고들어볼 수 있습니다.

| 도구 | 역할 | 상세 |
|------|------|------|
| **gstack** | 아이디어 검증 · 플랜 리뷰 워크플로 | `아이디어 있어` 키워드로 자동 진입. YC 스타일 6개 질문으로 실현 가능성 체크 |
| **gws** | Google Workspace 자동화 | Gmail, Calendar, Drive, Sheets를 Claude에서 직접 제어. `gws` 바이너리 필요 |
| **gbrain** | 런북·SOP·지식 관리 | `런북 써줘` 한 마디로 담당자·검토주기 포함한 실전 SOP 작성 |

---

이 레포가 도움이 됐다면 ⭐ Star 눌러주세요. 업데이트 알림도 받을 수 있습니다.
