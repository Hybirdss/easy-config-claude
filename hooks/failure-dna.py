#!/usr/bin/env python3
"""PostToolUseFailure hook: Failure DNA

같은 에러가 2번 이상 반복되면 이전 실패 기록을 주입해서
Claude가 같은 디버깅 루프를 반복하지 않게 한다.

저장 경로: ~/.claude/failure-dna/{fingerprint}.json
핑거프린트 = md5(tool + 정규화된 에러 패턴)[:12]
"""
import hashlib
import json
import os
import re
import sys
import time
from pathlib import Path

DNA_DIR = Path.home() / ".claude" / "failure-dna"
DNA_DIR.mkdir(parents=True, exist_ok=True)

MAX_HISTORY = 10        # 핑거프린트당 최대 저장 횟수
INJECT_THRESHOLD = 2    # 이 횟수 이상 반복 시 경고 주입
COOLDOWN_SECONDS = 30   # 같은 핑거프린트 30초 이내 재주입 방지


def fingerprint(tool: str, error: str) -> str:
    normalized = re.sub(r"/[\w/._-]+", "<PATH>", error)
    normalized = re.sub(r"\b\d{4,}\b", "<N>", normalized)
    normalized = re.sub(r"session=\S+", "session=<S>", normalized)
    normalized = re.sub(r"\s+", " ", normalized).strip()[:200]
    key = f"{tool}:{normalized}"
    return hashlib.md5(key.encode()).hexdigest()[:12]


def load_dna(fp: str) -> dict:
    path = DNA_DIR / f"{fp}.json"
    if path.exists():
        try:
            return json.loads(path.read_text())
        except Exception:
            pass
    return {"fingerprint": fp, "count": 0, "attempts": [], "last_inject": 0}


def save_dna(fp: str, data: dict) -> None:
    (DNA_DIR / f"{fp}.json").write_text(json.dumps(data, indent=2))


def main():
    raw = sys.stdin.read()
    if not raw.strip():
        return

    try:
        event = json.loads(raw)
    except json.JSONDecodeError:
        return

    tool = event.get("tool_name", "unknown")
    error = event.get("error", "") or str(event.get("tool_result", ""))
    if not error:
        return

    fp = fingerprint(tool, error)
    dna = load_dna(fp)

    now = time.time()
    dna["count"] += 1
    dna["attempts"] = (dna["attempts"] + [{
        "ts": int(now),
        "error_snippet": error[:200],
    }])[-MAX_HISTORY:]

    if dna["count"] >= INJECT_THRESHOLD:
        since_last = now - dna.get("last_inject", 0)
        if since_last > COOLDOWN_SECONDS:
            dna["last_inject"] = now
            prev = dna["attempts"][-2]["error_snippet"] if len(dna["attempts"]) >= 2 else ""
            print(
                f"\n[Failure DNA] 이 에러 패턴 {dna['count']}번째 반복 (tool: {tool}).\n"
                f"이전 실패: {prev[:120]}\n"
                f"다른 접근법을 시도하거나 Opus로 전환하세요 (/model opus)."
            )

    save_dna(fp, dna)


if __name__ == "__main__":
    main()
