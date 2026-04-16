## Supabase Rules

### RLS (Row Level Security) 필수

모든 테이블에 RLS를 활성화하고, 정책을 명시적으로 설정한다.

```sql
-- ✗ RLS 없이 테이블 생성
CREATE TABLE posts (id uuid, user_id uuid, content text);

-- ✓ RLS 활성화 + 정책 설정
CREATE TABLE posts (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid REFERENCES auth.users NOT NULL, content text);

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users can read own posts"
  ON posts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "users can insert own posts"
  ON posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

**RLS 없는 테이블 = 모든 유저가 모든 데이터 접근 가능.**

### Service Role Key vs Anon Key

| 키 | 어디서 | 용도 |
|----|--------|------|
| `anon` | 클라이언트 (브라우저) | 공개 데이터 읽기, 인증된 유저 본인 데이터 |
| `service_role` | **서버 전용** | RLS 우회, admin 작업, 백그라운드 잡 |

`service_role` 키가 클라이언트 번들에 포함되면 즉시 보안 사고.

```ts
// ✗ 클라이언트 컴포넌트에서 service_role 사용
const supabase = createClient(url, process.env.SUPABASE_SERVICE_ROLE_KEY)

// ✓ Server Action / Route Handler에서만
// app/actions.ts (서버 전용)
const supabase = createClient(url, process.env.SUPABASE_SERVICE_ROLE_KEY)
```

### 마이그레이션 안전 규칙

```sql
-- ✗ 롤백 불가한 컬럼 삭제
ALTER TABLE users DROP COLUMN phone;

-- ✓ 먼저 NOT NULL 제거 → 사용 중단 → 나중에 삭제
ALTER TABLE users ALTER COLUMN phone DROP NOT NULL;
-- (코드에서 phone 참조 제거 후)
-- (다음 마이그레이션에서 컬럼 삭제)
```

**대용량 테이블 컬럼 추가:**
```sql
-- ✗ NOT NULL + DEFAULT가 있으면 테이블 락 발생 (행 수백만 개 시 수분)
ALTER TABLE events ADD COLUMN processed boolean NOT NULL DEFAULT false;

-- ✓ nullable로 추가 → 백필 → NOT NULL 추가
ALTER TABLE events ADD COLUMN processed boolean;
UPDATE events SET processed = false WHERE processed IS NULL;
ALTER TABLE events ALTER COLUMN processed SET NOT NULL;
```

### Edge Functions

```ts
// CPU 시간 50ms 한도 — 무거운 연산 금지
// 메모리 512MB 한도
// 외부 fetch: 타임아웃 반드시 설정

const response = await fetch(url, {
  signal: AbortSignal.timeout(5000)  // 5초 타임아웃
})
```

Edge Function에서 직접 DB 연결 대신 **Supabase 클라이언트** 사용.

### Realtime

```ts
// ✗ cleanup 없이 구독 — 메모리 누수
supabase.channel('posts').on('postgres_changes', ...).subscribe()

// ✓ 언마운트 시 구독 해제
useEffect(() => {
  const channel = supabase
    .channel('posts')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'posts' }, handler)
    .subscribe()

  return () => { supabase.removeChannel(channel) }
}, [])
```

### 쿼리 패턴

```ts
// ✗ N+1: 유저마다 별도 쿼리
for (const user of users) {
  const { data } = await supabase.from('posts').select().eq('user_id', user.id)
}

// ✓ 한 번에 조인
const { data } = await supabase
  .from('users')
  .select(`*, posts(*)`)
  .in('id', userIds)
```
