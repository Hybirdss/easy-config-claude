# easy-config-claude

Claude Code 최적화 세팅 레포. "설정해줘" 한 마디면 토큰 60% 절감 + 에이전트 하네스 즉시 적용.

@./rules/guardrails.md
@./rules/conventions.md
@./rules/model-routing.md
@./rules/intelligence.md

## 슬래시 커맨드 (자주 쓰는 것)

| 커맨드 | 설명 | Read 경로 |
|--------|------|----------|
| 커밋, commit | 커밋 메시지 생성 + 스테이징 | `./skills/commit/SKILL.md` |
| 코드 리뷰, review | diff 기반 리뷰 (CRITICAL/HIGH/MEDIUM) | `./skills/review/SKILL.md` |
| 설정해줘, setup | 로컬 환경 자동 최적화 | `./skills/setup/SKILL.md` |
| 진단, diagnose | 세팅 건강도 0-100점 | `./skills/diagnose/SKILL.md` |

## Skills-Lib (키워드 자동 감지)

| 트리거 키워드 | 스킬 | Read 경로 |
|-------------|------|----------|
| 아이디어, 이거 만들만해, 플랜 리뷰, 기획 검토 | gstack | `./skills-lib/gstack/SKILL.md` |
| Gmail, 구글 캘린더, Drive, 스프레드시트 | gws | `./skills-lib/gws/SKILL.md` |
| 런북, SOP, 플레이북, 온보딩 문서, 브랜드 보이스 | second-brain | `./skills-lib/second-brain/SKILL.md` |
