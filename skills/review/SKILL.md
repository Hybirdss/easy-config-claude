---
name: review
description: 변경된 코드를 diff 기반으로 리뷰. 버그·보안·타입 안전성·엣지케이스를 체크하고 심각도별로 정리. 트리거: 코드 리뷰, review, PR 리뷰, 이 코드 어때, 머지해도 돼.
---

# Review

**목표:** diff를 읽고 실제로 문제가 될 것만 짚는다. 취향 지적이 아니라 버그·보안·동작 오류 중심.

## 1. 리뷰 대상 파악

```bash
# 브랜치 기준 diff
git diff main...HEAD --stat 2>/dev/null || git diff --stat HEAD~1

# 변경 파일 목록
git diff main...HEAD --name-only 2>/dev/null || git diff --name-only HEAD~1
```

파일 목록을 확인하고 핵심 파일의 diff를 읽는다:

```bash
git diff main...HEAD -- <핵심파일> 2>/dev/null || git diff HEAD~1 -- <핵심파일>
```

## 2. 체크리스트

### CRITICAL (머지 차단)
- [ ] 런타임 에러 발생 가능한 코드 (null/undefined 접근, 타입 불일치)
- [ ] 보안 취약점 (SQL injection, XSS, 하드코딩 크리덴셜, unvalidated input)
- [ ] 데이터 유실 가능성 (DELETE without WHERE, 비가역적 마이그레이션)
- [ ] 인증/인가 누락 (protected route에 auth check 없음)

### HIGH (강력 권고)
- [ ] 엣지케이스 미처리 (빈 배열, null 입력, 네트워크 실패)
- [ ] 메모리/리소스 누수 (열린 파일 핸들, 이벤트 리스너 미정리)
- [ ] 잘못된 async/await (unhandled Promise, race condition)
- [ ] 테스트 없는 새 비즈니스 로직

### MEDIUM (개선 권고)
- [ ] N+1 쿼리 패턴
- [ ] 하드코딩된 매직 넘버/문자열
- [ ] 에러 메시지가 너무 자세해서 정보 노출

### LOW (선택적)
- [ ] 타입 any 사용
- [ ] 중복 코드 (3회 이상 반복)

## 3. 결과 출력

발견된 이슈만 출력한다. 없으면 "이슈 없음"으로 끝낸다.

```
## 코드 리뷰 결과

### CRITICAL
- **[파일:라인]** [구체적 문제 설명]
  ```코드 스니펫```
  → 수정안: [구체적 제안]

### HIGH
- **[파일:라인]** [문제]
  → 수정안: [제안]

### (이슈 없는 등급은 생략)

---
총 이슈: CRITICAL 0 / HIGH 1 / MEDIUM 2 / LOW 0
머지 판단: [LGTM / CRITICAL 해결 후 머지 / 재검토 필요]
```

## 판단 기준

- CRITICAL 0개 → **LGTM**
- CRITICAL 1개+ → **머지 차단**
- HIGH가 많아도 CRITICAL 없으면 → **조건부 LGTM** (HIGH 해결 권고)

## 팁: 특정 파일만 리뷰

```bash
git diff HEAD -- src/api/auth.ts | head -300
```

파일 지정해서 말해주면 해당 파일만 집중 리뷰한다.
