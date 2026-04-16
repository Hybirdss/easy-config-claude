---
name: techdebt
description: 코드베이스 기술 부채 정기 점검. 5분 이내 처리 가능한 것부터 처리. 양치질처럼 습관적으로. 트리거: techdebt, 기술부채, 부채 점검, /techdebt
---

# Techdebt

**목표:** 쌓인 부채를 한 번에 다 갚으려 하지 않는다. 오늘 처리할 것과 다음에 처리할 것을 나눈 뒤, 오늘 치만 바로 고친다.

---

## 1. 부채 스캔

```bash
# TODO / FIXME / HACK / XXX / WORKAROUND 주석
grep -rn "TODO\|FIXME\|HACK\|XXX\|WORKAROUND" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" \
  --exclude-dir=node_modules --exclude-dir=.git \
  . 2>/dev/null | head -50

# any 타입 (TypeScript)
grep -rn ": any\b\|as any\b" \
  --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules . 2>/dev/null | grep -v "\.d\.ts" | head -30

# console.log 잔재 (프로덕션 코드)
grep -rn "console\.log\|console\.error\|console\.warn" \
  --include="*.ts" --include="*.tsx" --include="*.js" \
  --exclude-dir=node_modules --exclude-dir=__tests__ --exclude-dir=test \
  . 2>/dev/null | head -30

# 하드코딩된 URL / API endpoint
grep -rn "http://\|https://" \
  --include="*.ts" --include="*.tsx" --include="*.js" \
  --exclude-dir=node_modules --exclude-dir=.git \
  . 2>/dev/null | grep -v "test\|spec\|example\|README" | head -20

# 빈 catch 블록
grep -rn "catch\s*(.*)\s*{\s*}" \
  --include="*.ts" --include="*.tsx" --include="*.js" \
  --exclude-dir=node_modules . 2>/dev/null | head -20

# deprecated / legacy 주석
grep -rn "@deprecated\|// legacy\|// old\|// temp\b\|// temporary" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" \
  --exclude-dir=node_modules . 2>/dev/null | head -20
```

## 2. 분류

스캔 결과를 두 버킷으로 나눈다:

### 오늘 처리 (5분 이내)
- 명확한 TODO라 답이 자명한 것
- `console.log` 제거
- 단순 `any` 타입 → 구체 타입으로 교체
- 빈 catch 블록 → 최소한 `logger.error` 추가
- 오래된 주석 삭제

### 다음에 처리 (계획 필요)
- 아키텍처 변경이 필요한 FIXME
- 하드코딩된 URL (환경변수 마이그레이션 필요)
- 복잡한 리팩토링
- 테스트 없는 로직 (테스트 작성 필요)

## 3. 오늘 치 처리

분류 후 **오늘 처리** 항목만 바로 고친다.

- 한 번에 한 파일씩
- 수정 후 `git diff`로 의도치 않은 변경 없는지 확인
- 테스트 있으면 실행해서 통과 확인

## 4. 결과 출력

```
## Techdebt 점검 결과 — [날짜]

### 처리 완료
- [파일:라인] [무엇을 어떻게 고쳤는지]
- ...

### 다음 세션에
- [파일:라인] [문제 설명] (예상 소요: X분)
- ...

오늘 처리: N건 / 잔여 부채: M건
```

---

## 팁: 주기적으로 쓰는 방법

```
# 매주 월요일 작업 시작 전
techdebt
```

처음엔 많이 나와도 괜찮습니다. 매주 하면 빠르게 줄어듭니다.

범위를 좁히고 싶으면:
```
techdebt src/api/
techdebt src/components/Auth.tsx
```

특정 타입만 보고 싶으면:
```
techdebt --only todos
techdebt --only types
```
