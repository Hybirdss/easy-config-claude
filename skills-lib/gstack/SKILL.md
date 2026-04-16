---
name: gstack
description: 아이디어 검증(YC 오피스아워), 레퍼런스 리서치(scout), 플랜 리뷰(CEO/엔지니어링/디자인), 자동 플랜 파이프라인(autoplan). 트리거: 아이디어 있어, 이거 만들만해?, 플랜 리뷰, office hours, scout, 레퍼런스 찾아줘, 설계 검토.
---

# gstack — 아이디어·플랜 워크플로 허브

gstack이 로컬에 설치돼 있으면 `~/.claude/skills/gstack/` 하위 sub-skill로 라우팅한다.
설치 안 된 경우 아래 standalone 로직으로 동작한다.

---

## 라우팅

```bash
GSTACK_PATH="$HOME/.claude/skills/gstack"
if [ -d "$GSTACK_PATH" ]; then
  echo "GSTACK_INSTALLED: yes"
  echo "→ ~/.claude/skills/gstack/ 의 해당 sub-skill을 Read하여 실행"
else
  echo "GSTACK_INSTALLED: no"
  echo "→ standalone 모드로 실행 (아래 로직)"
fi
```

gstack이 설치된 경우:
- 아이디어 검증 → `Read ~/.claude/skills/gstack/office-hours/SKILL.md`
- 레퍼런스 리서치 → `Read ~/.claude/skills/gstack/scout/SKILL.md` (또는 `~/.claude/skills/scout/SKILL.md`)
- 플랜 리뷰 (CEO) → `Read ~/.claude/skills/gstack/plan-ceo-review/SKILL.md`
- 플랜 리뷰 (엔지니어링) → `Read ~/.claude/skills/gstack/plan-eng-review/SKILL.md`
- 플랜 리뷰 (디자인) → `Read ~/.claude/skills/gstack/plan-design-review/SKILL.md`
- 전체 자동 → `Read ~/.claude/skills/gstack/autoplan/SKILL.md`

---

## Standalone: 아이디어 검증 (YC 오피스아워 스타일)

gstack 미설치 시 아래 6개 질문으로 아이디어를 검증한다.

### 6 Forcing Questions

아이디어를 받으면 순서대로 물어본다. 사용자가 답하면 다음으로. 답이 약하면 파고든다.

**Q1. 수요 현실성**
> "지금 이 문제를 해결하려고 돈/시간을 쓰는 사람이 실제로 있나요?
> 직접 본 사람이 있으면 말해줘요. '있을 것 같다'는 답변은 패스."

**Q2. 현재 대안**
> "지금 이 사람들이 이 문제를 어떻게 해결하고 있나요?
> 아무것도 안 하거나, 엑셀 쓰거나, 경쟁사 쓰거나 — 구체적으로."

**Q3. 왜 지금**
> "1년 전에는 왜 이게 없었나요? 지금 만들 수 있는 이유가 뭔가요?
> (기술 변화, 규제, 시장 타이밍 중 하나여야 함)"

**Q4. 좁은 쐐기 (Narrow Wedge)**
> "처음 10명의 유저는 누구예요? 직업, 나이, 어디 사나요?
> 이 10명한테 지금 당장 팔 수 있어요?"

**Q5. 직접 관찰**
> "이 문제를 직접 겪어봤나요? 아니면 주변에서 봤나요?
> 구체적인 에피소드를 말해줘요."

**Q6. 미래 적합성**
> "5년 후에 이 시장이 더 크거나 더 작을 것 같아요?
> 왜 그렇게 생각해요?"

### 결과 판정

6개 답변을 분석해서:

```
[ VERDICT ]
수요 현실성:   ★★★★☆
대안 존재:     ★★★☆☆
타이밍:        ★★★★★
좁은 쐐기:     ★★★☆☆
직접 관찰:     ★★★★☆
미래 적합성:   ★★★☆☆

총평: [PROCEED / PIVOT / KILL]

→ PROCEED: 만들어 보세요. 리스크는 [X]
→ PIVOT: 방향을 [Y]로 바꾸면 더 강해짐
→ KILL: [Z] 가정이 틀렸음. 다음 아이디어로.
```

---

## gstack 설치 방법

gstack은 [gstack 저장소](https://github.com/your-org/gstack)에서 설치합니다.
(설치 경로: `~/.claude/skills/gstack/`)

설치 후 이 스킬을 다시 실행하면 자동으로 full 버전으로 전환됩니다.
