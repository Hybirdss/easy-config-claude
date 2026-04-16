## Python Rules

### 타입 힌트는 모든 함수에

```python
# ✗
def get_user(user_id):
    return db.query(user_id)

# ✓
def get_user(user_id: int) -> User | None:
    return db.query(user_id)
```

Python 3.10+: `Union[X, Y]` 대신 `X | Y`. `Optional[X]` 대신 `X | None`.
`Any` 사용 시 주석 필수: `# TODO: narrow this type`

### async 올바른 사용

```python
# ✗ async 함수 안에서 블로킹 IO — 이벤트 루프 멈춤
async def fetch_data():
    data = requests.get(url)  # 블로킹
    file = open("data.txt")   # 블로킹

# ✓
async def fetch_data():
    async with httpx.AsyncClient() as client:
        data = await client.get(url)
    async with aiofiles.open("data.txt") as f:
        content = await f.read()
```

`time.sleep()` → `await asyncio.sleep()`.
`requests` → `httpx` (async 지원).

### 리소스 관리

```python
# ✗ 파일/DB 커넥션 명시적 close 없이 열기
f = open("data.txt")
conn = get_db_connection()

# ✓ with 문으로 자동 정리 보장
with open("data.txt") as f:
    content = f.read()

with get_db_connection() as conn:
    result = conn.execute(query)
```

### 예외 처리

```python
# ✗ 모든 예외 삼킴
try:
    process()
except:
    pass

# ✗ 너무 넓은 Exception
try:
    process()
except Exception:
    pass

# ✓ 구체적 예외 + 최소한 로깅
try:
    process()
except (ValueError, KeyError) as e:
    logger.error("processing failed: %s", e)
    raise
```

### 현대적 문법

```python
# 경로: os.path 대신 pathlib
from pathlib import Path
config = Path("~/.config").expanduser() / "app.json"

# 문자열: .format() 대신 f-string
name = f"Hello, {user.name}!"

# 구조화 데이터: dict 대신 dataclass 또는 pydantic
from dataclasses import dataclass

@dataclass
class UserConfig:
    host: str
    port: int = 5432
    debug: bool = False

# 리스트 컴프리헨션 (단순한 경우만, 복잡하면 for 루프)
active_users = [u for u in users if u.is_active]
```

### 보안 주의사항

```python
# ✗ eval / exec 사용 — 코드 인젝션
eval(user_input)
exec(template.format(user_input))

# ✗ pickle로 외부 데이터 역직렬화 — RCE 위험
pickle.loads(untrusted_bytes)

# ✗ shell=True로 사용자 입력 실행
subprocess.run(f"cmd {user_input}", shell=True)

# ✓ 리스트로 전달
subprocess.run(["cmd", user_input])
```

### 테스트

- 단위 테스트: `pytest` (unittest 금지)
- 픽스처: `@pytest.fixture`
- 목킹: `unittest.mock.patch` 또는 `pytest-mock`
- 파일명: `test_*.py` 또는 `*_test.py`
