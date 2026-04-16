## Next.js (App Router) Rules

### Server Component가 기본이다

새 컴포넌트를 만들 때 `'use client'`는 없는 것이 기본값이다.
`'use client'` 추가가 필요한 경우만:
- `useState`, `useEffect`, `useRef` 등 React 훅 사용
- 브라우저 API 직접 접근 (`window`, `document`, `localStorage`)
- 이벤트 핸들러 (onClick, onChange 등)
- 외부 클라이언트 전용 라이브러리

"잘 모르겠으면 `use client` 붙이자"는 금지. Server Component로 시작하고 필요할 때만 전환한다.

### 데이터 페칭

```ts
// ✓ Server Component에서 직접 fetch
async function ProductPage({ params }: { params: { id: string } }) {
  const product = await fetch(`/api/products/${params.id}`, {
    next: { revalidate: 60 }  // ISR
  }).then(r => r.json())
  return <Product data={product} />
}

// ✗ useEffect로 클라이언트 페칭 (Server Component에서 할 수 있는데)
'use client'
function ProductPage() {
  const [product, setProduct] = useState(null)
  useEffect(() => { fetch(...).then(...) }, [])
}
```

### Server Actions vs Route Handlers

| 상황 | 선택 |
|------|------|
| 폼 제출, 버튼 클릭 → DB 쓰기 | **Server Action** |
| 외부 서비스가 호출하는 webhook | **Route Handler** |
| 모바일 앱 / 외부 클라이언트 API | **Route Handler** |
| 같은 Next.js 앱 내부 mutation | **Server Action** |

### 파일 컨벤션

```
app/
├── layout.tsx        전체 레이아웃 (한 번만)
├── loading.tsx       Suspense fallback 자동 적용
├── error.tsx         에러 바운더리 (반드시 'use client')
├── not-found.tsx     404
└── page.tsx          페이지 (기본 Server Component)
```

`loading.tsx`가 있으면 `<Suspense>` 수동 작성 불필요.

### 성능 주의사항

- `generateStaticParams` 없는 동적 라우트는 요청마다 렌더링 → 의도적인지 확인
- 이미지는 항상 `next/image` — `<img>` 직접 사용 금지
- 폰트는 `next/font` — 외부 `@import` 금지
- `'use client'` 컴포넌트 안에 Server Component를 children으로 전달 가능 — 트리 분리 활용

### 흔한 실수

```ts
// ✗ params를 await 없이 사용 (Next.js 15+에서 에러)
export default function Page({ params }) {
  const { id } = params  // 동기 접근
}

// ✓
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
}
```

```ts
// ✗ Server Component에서 Context 사용 (불가)
const ctx = useContext(MyContext)

// ✓ Props로 내려주거나, Context Provider를 Client Component로 분리
```
