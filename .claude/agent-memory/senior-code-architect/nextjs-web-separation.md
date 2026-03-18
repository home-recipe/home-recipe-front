# Next.js 웹 프론트엔드 분리 프로젝트

## 개요
- 날짜: 2026-03-19
- Flutter 웹/앱 통합 프로젝트에서 Next.js 웹 프론트엔드 분리
- 프로젝트 루트에 Next.js 파일 직접 생성 (src/ 디렉토리 사용)
- 기존 Flutter 파일과 충돌 없이 공존

## 프로젝트 구조

### 루트 레벨 파일
- `package.json`: Next.js 의존성 (next ^15.1.0, react ^19.0.0, tailwindcss ^4.0.0)
- `tsconfig.json`: TypeScript 설정 (Flutter 디렉토리 exclude)
- `next.config.ts`: Next.js 설정 (이미지 최적화)
- `postcss.config.mjs`: Tailwind CSS v4 설정
- `.env.local`, `.env.production`: 환경 변수
- `.gitignore`: Next.js 관련 항목 추가 (.next/, node_modules/, .env.local)

### src/ 디렉토리 구조
```
src/
├── app/                      # Next.js App Router
│   ├── globals.css          # 전역 스타일 (Tailwind + CSS 변수)
│   ├── layout.tsx           # 루트 레이아웃 (AuthProvider)
│   ├── page.tsx             # 홈 페이지
│   ├── login/               # 로그인 페이지
│   ├── login-callback/      # OAuth2 콜백
│   ├── signup/              # 회원가입
│   └── recipes/             # 레시피 목록 및 상세 (SSR)
├── components/auth/         # AuthProvider (전역 인증 상태)
├── hooks/                   # useAuth Hook
├── lib/
│   ├── api/                 # client.ts, auth.ts, recipe.ts
│   ├── auth/                # token.ts, pkce.ts
│   └── config.ts            # 환경 설정
└── types/                   # api.ts, models.ts
```

## 핵심 아키텍처 결정

### 1. API 클라이언트 (client.ts)
- Axios 인스턴스 (baseURL, withCredentials: true)
- 요청 인터셉터: Authorization 헤더, X-Client-Type: WEB 자동 추가
- 응답 인터셉터: AUTH_EXPIRED_TOKEN 감지 → 자동 토큰 재발급
- isRefreshing 플래그 + failedQueue로 동시 요청 처리
- forceLogout() 함수: 토큰 삭제 + /login 리다이렉트

### 2. 토큰 관리 (token.ts)
- localStorage 사용 (SSR 대비 메모리 폴백)
- accessToken, userRole 저장
- refreshToken은 서버가 HttpOnly 쿠키로 관리 (웹 보안)

### 3. PKCE 서비스 (pkce.ts)
- code_verifier: 128자 무작위 문자열 (A-Za-z0-9-._~)
- code_challenge: SHA-256 해시 → Base64 URL 인코딩
- Web Crypto API 사용

### 4. 인증 API (auth.ts)
- exchangeCodeForTokens(): Axios 인터셉터 우회 (직접 axios.post)
- X-Client-Type: WEB 헤더 필수
- refreshAccessToken(): HttpOnly 쿠키 자동 전송

### 5. SSR + SEO (recipes/[id]/page.tsx)
- Server Component로 구현
- generateMetadata(): 동적 메타 태그 (Open Graph, Twitter Card)
- JSON-LD 구조화된 데이터 (Recipe Schema)
- fetch() 직접 사용 (Axios는 클라이언트 전용)

## Clean Architecture 적용

### 레이어 구조
1. **Presentation**: app/, components/ (UI)
2. **Application**: hooks/ (비즈니스 로직 조율)
3. **Domain**: types/ (데이터 모델)
4. **Infrastructure**: lib/api/, lib/auth/ (외부 통신)

### SOLID 원칙
- **Single Responsibility**: 각 모듈이 하나의 책임만 가짐
- **Dependency Inversion**: 타입 정의 분리 (types/)

## 스타일링

### Tailwind CSS v4
- PostCSS 플러그인: @tailwindcss/postcss
- 커스텀 CSS 변수 (globals.css):
  - --color-primary-orange: #f21d1d (REC::)
  - --color-primary-green: #19e619 (OOK)
  - 그라디언트 텍스트 클래스: .gradient-text-rec, .gradient-text-ook

### 폰트
- Google Fonts: Nanum Gothic Coding
- letter-spacing: 0.5px

## 주요 페이지

### 1. 홈 페이지 (page.tsx)
- Client Component
- 인증 여부에 따라 다른 CTA 버튼
- 3개 기능 소개 카드

### 2. 로그인 페이지 (login/page.tsx)
- 이메일/비밀번호 폼
- Google, Kakao 소셜 로그인 버튼
- PKCE 흐름 시작 (code_verifier 생성 → OAuth URL 이동)

### 3. 로그인 콜백 (login-callback/page.tsx)
- Suspense로 감싸기 (useSearchParams 사용)
- code 파라미터 추출 → exchangeCodeForTokens()
- 구버전 서버 감지 (accessToken 파라미터 경고)

### 4. 회원가입 (signup/page.tsx)
- 이메일 중복 확인 버튼
- 비밀번호 확인 검증
- 성공 시 /login 리다이렉트

### 5. 레시피 목록 (recipes/page.tsx)
- Client Component
- 인증 가드: isAuthenticated 확인
- 레시피 생성 버튼
- 카드 형태로 목록 표시

### 6. 레시피 상세 (recipes/[id]/page.tsx)
- Server Component (SSR)
- generateMetadata() 함수
- JSON-LD 스키마
- RecipeDetailClient (Client Component)로 UI 렌더링

## 환경 변수

### 개발 (.env.local)
- NEXT_PUBLIC_API_BASE_URL: http://localhost:8080
- NEXT_PUBLIC_OAUTH_SERVER_URL: https://recook-server.site

### 프로덕션 (.env.production)
- NEXT_PUBLIC_API_BASE_URL: https://recook.kr
- NEXT_PUBLIC_OAUTH_SERVER_URL: https://recook-server.site

## Flutter와의 차이점

| 항목 | Flutter | Next.js |
|------|---------|---------|
| RefreshToken 저장 | Secure Storage | HttpOnly 쿠키 (서버) |
| SSR | 불가능 | 가능 (레시피 상세) |
| SEO | 제한적 | 완전 지원 |
| HTTP 클라이언트 | Dio | Axios |
| 상태 관리 | Provider | Context API |

## 트러블슈팅

### npm 캐시 권한 오류
- 증상: EACCES, EEXIST 오류
- 해결: `sudo chown -R $(whoami) ~/.npm`
- 또는: `sudo chown -R 501:20 ~/.npm`

### 설치 명령어
```bash
# 권한 수정 후
npm cache clean --force
npm install
npm run dev
```

## 파일 경로 참조

### 주요 파일
- API 클라이언트: `/Users/mikyeong/project/home-recipe-front/src/lib/api/client.ts`
- 인증 API: `/Users/mikyeong/project/home-recipe-front/src/lib/api/auth.ts`
- 토큰 관리: `/Users/mikyeong/project/home-recipe-front/src/lib/auth/token.ts`
- PKCE: `/Users/mikyeong/project/home-recipe-front/src/lib/auth/pkce.ts`
- AuthProvider: `/Users/mikyeong/project/home-recipe-front/src/components/auth/AuthProvider.tsx`
- 루트 레이아웃: `/Users/mikyeong/project/home-recipe-front/src/app/layout.tsx`
- 전역 스타일: `/Users/mikyeong/project/home-recipe-front/src/app/globals.css`

### 설정 파일
- package.json: `/Users/mikyeong/project/home-recipe-front/package.json`
- tsconfig.json: `/Users/mikyeong/project/home-recipe-front/tsconfig.json`
- next.config.ts: `/Users/mikyeong/project/home-recipe-front/next.config.ts`
- README: `/Users/mikyeong/project/home-recipe-front/NEXT_README.md`

## 코딩 컨벤션

### TypeScript
- 모든 함수에 JSDoc 주석 (한글)
- strict mode 활성화
- 타입 정의 분리 (types/)

### 네이밍
- 파일명: camelCase (컴포넌트는 PascalCase)
- 함수명: camelCase (동사로 시작)
- 타입명: PascalCase (Interface, Type)

### 코드 스타일
- 한 줄 최대 100자
- 들여쓰기: 2 스페이스
- 세미콜론 사용
- 작은따옴표 사용

## 다음 단계 (구현 완료)

- [x] Phase 1: 프로젝트 초기 설정
- [x] Phase 2: 환경 설정 및 타입 정의
- [x] Phase 3: 토큰 관리 및 PKCE 서비스
- [x] Phase 4: API 클라이언트
- [x] Phase 5: 인증 API
- [x] Phase 6: 레시피 API
- [x] Phase 7: 커스텀 Hook 및 AuthProvider
- [x] Phase 8: 로그인 페이지
- [x] Phase 9: 로그인 콜백 페이지
- [x] Phase 10: 회원가입 페이지
- [x] Phase 11: 레시피 목록 페이지
- [x] Phase 12: 레시피 상세 페이지 (SSR + SEO)
- [x] 전역 스타일 및 레이아웃
- [x] README 작성

## 추가 개선 사항 (선택)

- [ ] 로딩 상태 공통 컴포넌트
- [ ] 에러 바운더리
- [ ] 페이지네이션
- [ ] 검색 기능
- [ ] 다국어 지원 (i18n)
- [ ] 테스트 코드 (Jest, Testing Library)
- [ ] Storybook 통합
- [ ] Docker 이미지
- [ ] CI/CD 파이프라인
