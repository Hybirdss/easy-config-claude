---
name: gws
description: Google Workspace 자동화. Gmail 읽기/발송/분류, Google Calendar 일정 관리, Drive 파일 업로드, Sheets 읽기/쓰기, 주간 요약, 스탠드업 리포트. 트리거: Gmail, 메일 보내줘, 캘린더, 일정, Google Drive, 스프레드시트, 주간 요약, 스탠드업.
---

# gws — Google Workspace 자동화

**필요 조건:** `gws` CLI 바이너리 설치 + Google OAuth 인증.

---

## 바이너리 체크

```bash
if command -v gws &>/dev/null; then
  echo "GWS_INSTALLED: yes"
  gws --version 2>/dev/null || echo "(버전 확인 불가)"
else
  echo "GWS_INSTALLED: no"
fi
```

**`gws` 미설치 시** — 아래 설치 가이드를 보여준다. 설치 전에는 GWS 기능 사용 불가.

---

## 설치 가이드 (gws 미설치 시)

### 1. gws CLI 설치

```bash
# npm으로 설치
npm install -g @your-org/gws

# 또는 직접 다운로드
curl -sSL https://install.gws.dev | bash
```

### 2. Google OAuth 인증

```bash
gws auth login
```

브라우저에서 Google 계정 선택 → 권한 허용.
필요 스코프: Gmail, Calendar, Drive, Sheets (read/write).

### 3. 스킬 생성 (선택)

```bash
gws generate-skills
```

`~/.claude/skills-lib/gws-*/SKILL.md` 파일들이 자동 생성됩니다.

---

## 기능 라우팅 (gws 설치 후)

사용자 요청에 따라 아래 명령을 실행한다.

### Gmail

| 요청 | 명령 |
|------|------|
| 읽지 않은 메일 보여줘 | `gws gmail +triage` |
| [주소]에 [내용] 보내줘 | `gws gmail +send --to "[주소]" --subject "[제목]" --body "[내용]"` |
| [메일]에 답장해줘 | `gws gmail +reply --message-id "[ID]" --body "[내용]"` |

```bash
# 받은 메일 요약
gws gmail +triage

# 메일 발송
gws gmail +send \
  --to "recipient@example.com" \
  --subject "제목" \
  --body "본문"
```

### Google Calendar

| 요청 | 명령 |
|------|------|
| 오늘 일정 보여줘 | `gws calendar +agenda --today` |
| 내일 [시간] [제목] 일정 만들어줘 | `gws calendar +insert` |
| 다음 회의 준비해줘 | `gws workflow +meeting-prep` |

```bash
# 오늘 일정 조회
gws calendar +agenda --days 1

# 일정 생성
gws calendar +insert \
  --summary "회의 제목" \
  --start "2026-04-17T10:00:00" \
  --end "2026-04-17T11:00:00"
```

### Google Drive & Sheets

| 요청 | 명령 |
|------|------|
| [파일] Drive에 올려줘 | `gws drive +upload --file "[파일경로]"` |
| [스프레드시트] [범위] 읽어줘 | `gws sheets +read --id "[ID]" --range "[A1:Z100]"` |
| [데이터] [시트]에 추가해줘 | `gws sheets +append` |

### 워크플로 (고급)

```bash
# 스탠드업 리포트 (오늘 회의 + 미완료 태스크)
gws workflow +standup-report

# 주간 요약 (이번 주 회의 + 읽지 않은 메일 수)
gws workflow +weekly-digest

# 메일 → 태스크 변환
gws workflow +email-to-task --message-id "[ID]"
```

---

## 에러 처리

| 에러 | 대응 |
|------|------|
| `gws: command not found` | 설치 가이드 안내 |
| `Auth required` | `gws auth login` 실행 |
| `Insufficient scope` | `gws auth login --scope all` 재실행 |
| API rate limit | 잠시 후 재시도, 배치 요청으로 변환 |
