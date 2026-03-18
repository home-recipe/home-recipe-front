# REC::OOK Web Frontend (Next.js)

Flutter 웹/앱 통합 프로젝트에서 분리된 Next.js 기반 웹 프론트엔드입니다.

## 프로젝트 구조

```
/Users/mikyeong/project/home-recipe-front/
├── src/                          # Next.js 소스 코드
│   ├── app/                      # Next.js App Router 페이지
│   │   ├── globals.css          # 전역 스타일 (Tailwind CSS)
│   │   ├── layout.tsx           # 루트 레이아웃
│   │   ├── page.tsx             # 홈 페이지
│   │   ├── login/               # 로그인 페이지
│   │   ├── login-callback/      # OAuth2 콜백 페이지
│   │   ├── signup/              # 회원가입 페이지
│   │   └── recipes/             # 레시피 목록 및 상세 페이지
│   ├── components/              # 재사용 가능한 컴포넌트
│   │   └── auth/                # 인증 관련 컴포넌트
│   │       └── AuthProvider.tsx # 전역 인증 상태 관리
│   ├── hooks/                   # 커스텀 Hooks
│   │   └── useAuth.ts           # 인증 Hook
│   ├── lib/                     # 비즈니스 로직 및 유틸리티
│   │   ├── api/                 # API 클라이언트
│   │   │   ├── client.ts        # Axios 기반 공통 클라이언트
│   │   │   ├── auth.ts          # 인증 API
│   │   │   └── recipe.ts        # 레시피 API
│   │   ├── auth/                # 인증 관련 로직
│   │   │   ├── token.ts         # 토큰 관리
│   │   │   └── pkce.ts          # PKCE 서비스
│   │   └── config.ts            # 환경 설정
│   └── types/                   # TypeScript 타입 정의
│       ├── api.ts               # API 공통 타입
│       └── models.ts            # 데이터 모델 타입
├── package.json                 # npm 의존성
├── tsconfig.json                # TypeScript 설정
├── next.config.ts               # Next.js 설정
├── postcss.config.mjs           # PostCSS 설정 (Tailwind CSS)
├── .env.local                   # 로컬 환경 변수
├── .env.production              # 프로덕션 환경 변수
└── (기존 Flutter 파일들)        # lib/, android/, ios/, web/ 등
```

## 주요 기능

### 1. 인증 시스템
- **이메일/비밀번호 로그인**: `/api/auth/login`
- **OAuth2 소셜 로그인**: Google, Kakao (PKCE 흐름)
- **자동 토큰 재발급**: Axios 인터셉터로 `AUTH_EXPIRED_TOKEN` 감지 시 자동 처리
- **HttpOnly 쿠키**: RefreshToken은 서버가 HttpOnly 쿠키로 관리 (보안)

### 2. 레시피 기능
- **레시피 생성**: AI 기반 레시피 추천
- **레시피 목록**: 사용자가 생성한 레시피 목록 조회
- **레시피 상세**: SSR + SEO 최적화 (Open Graph, JSON-LD)

### 3. SEO 최적화
- **Server Component**: 레시피 상세 페이지는 서버에서 렌더링
- **동적 메타데이터**: `generateMetadata()` 함수로 각 레시피마다 고유한 메타 태그
- **구조화된 데이터**: JSON-LD (Recipe Schema)로 검색 엔진 최적화

## 설치 및 실행

### 1. npm 캐시 권한 수정 (필요 시)

npm 캐시에 권한 문제가 있는 경우 다음 명령어를 실행하세요:

```bash
sudo chown -R $(whoami) ~/.npm
```

또는:

```bash
sudo chown -R 501:20 ~/.npm
```

### 2. 의존성 설치

```bash
npm install
```

### 3. 개발 서버 실행

```bash
npm run dev
```

브라우저에서 [http://localhost:3000](http://localhost:3000) 접속

### 4. 프로덕션 빌드

```bash
npm run build
npm start
```

## 환경 변수

### `.env.local` (로컬 개발)
```
NEXT_PUBLIC_API_BASE_URL=http://localhost:8080
NEXT_PUBLIC_OAUTH_SERVER_URL=https://recook-server.site
```

### `.env.production` (프로덕션)
```
NEXT_PUBLIC_API_BASE_URL=https://recook.kr
NEXT_PUBLIC_OAUTH_SERVER_URL=https://recook-server.site
```

## API 엔드포인트

### 인증
- `POST /api/auth/login` - 이메일/비밀번호 로그인
- `POST /api/auth/token` - OAuth2 코드를 Access Token으로 교환
- `POST /api/auth/logout` - 로그아웃
- `POST /api/auth/reissue` - Access Token 재발급
- `GET /api/user/me` - 현재 사용자 정보 조회
- `POST /api/user/email` - 이메일 중복 확인
- `POST /api/user` - 회원가입

### 레시피
- `POST /api/recipes` - 레시피 생성 (AI 생성)
- `GET /api/recipes` - 레시피 목록 조회
- `GET /api/recipes/{id}` - 레시피 상세 조회

## 주요 기술 스택

- **Next.js 15.1**: React 19 기반 풀스택 프레임워크
- **TypeScript 5.7**: 타입 안정성
- **Tailwind CSS 4.0**: 유틸리티 우선 CSS 프레임워크
- **Axios**: HTTP 클라이언트 (인터셉터로 자동 토큰 재발급)
- **Web Crypto API**: PKCE code_verifier 및 code_challenge 생성

## Clean Architecture 원칙

### Layered Architecture
1. **Presentation Layer** (`src/app`, `src/components`): UI 렌더링
2. **Application Layer** (`src/hooks`): 비즈니스 로직 조율
3. **Domain Layer** (`src/types`): 데이터 모델 및 타입
4. **Infrastructure Layer** (`src/lib/api`, `src/lib/auth`): 외부 서비스 통신

### SOLID 원칙
- **Single Responsibility**: 각 모듈은 하나의 책임만 가짐
- **Open/Closed**: 확장에는 열려있고 수정에는 닫혀있음
- **Dependency Inversion**: 인터페이스에 의존 (타입 정의 분리)

## 인증 흐름

### 이메일/비밀번호 로그인
1. 사용자가 이메일/비밀번호 입력
2. `POST /api/auth/login` 호출
3. 서버가 Access Token 반환 (+ RefreshToken은 HttpOnly 쿠키)
4. Access Token을 localStorage에 저장
5. 모든 API 요청에 `Authorization: Bearer <token>` 헤더 자동 추가

### OAuth2 소셜 로그인 (PKCE)
1. 클라이언트가 `code_verifier` 생성 (128자 무작위 문자열)
2. `code_verifier`를 SHA-256 해시 → Base64 URL 인코딩 → `code_challenge`
3. `code_challenge`와 함께 OAuth2 인증 URL로 리다이렉트
4. 사용자가 소셜 계정으로 로그인
5. 서버가 `code`를 포함한 콜백 URL로 리다이렉트
6. 클라이언트가 `code`와 `code_verifier`를 `POST /api/auth/token`으로 전송
7. 서버가 Access Token 반환 (+ RefreshToken은 HttpOnly 쿠키)

### 자동 토큰 재발급
1. API 요청 시 `AUTH_EXPIRED_TOKEN` 응답 수신
2. Axios 인터셉터가 자동으로 `POST /api/auth/reissue` 호출
3. 서버가 새 Access Token 반환
4. 새 Access Token으로 원래 요청 재시도
5. 동시 요청은 `failedQueue`로 관리 (중복 재발급 방지)

## Flutter와의 차이점

| 항목 | Flutter | Next.js (웹) |
|------|---------|-------------|
| **플랫폼** | 모바일(Android/iOS) + 웹 | 웹 전용 |
| **SSR** | 불가능 | 가능 (레시피 상세 페이지) |
| **SEO** | 제한적 | 완전 지원 (메타 태그, JSON-LD) |
| **RefreshToken 저장** | Secure Storage | HttpOnly 쿠키 (서버 관리) |
| **라우팅** | Navigator | App Router (파일 기반) |
| **상태 관리** | Provider | Context API (AuthProvider) |
| **HTTP 클라이언트** | Dio | Axios |

## 주의사항

1. **기존 Flutter 파일과 충돌 금지**: `lib/`, `android/`, `ios/`, `web/`, `pubspec.yaml` 등은 수정하지 마세요.
2. **tsconfig.json exclude**: Flutter 디렉토리를 exclude에 추가하여 TypeScript가 Flutter 파일을 처리하지 않도록 설정.
3. **X-Client-Type 헤더**: 모든 API 요청에 `X-Client-Type: WEB` 헤더 포함.
4. **withCredentials: true**: HttpOnly 쿠키 전송을 위해 필수.
5. **PKCE 흐름**: Flutter와 동일한 로직 (code_verifier 128자, SHA-256 + Base64 URL).

## 배포

### Vercel (추천)
1. GitHub에 푸시
2. Vercel에서 프로젝트 import
3. 환경 변수 설정 (`.env.production` 내용)
4. 자동 배포

### 기타 플랫폼
- **Netlify**: `next export` 사용 (SSR 불가)
- **AWS Amplify**: Next.js 지원
- **Docker**: `Dockerfile` 작성 후 컨테이너화

## 문제 해결

### npm 캐시 권한 오류
```bash
sudo chown -R $(whoami) ~/.npm
npm cache clean --force
npm install
```

### CORS 오류
- 백엔드 서버에서 `Access-Control-Allow-Origin` 헤더 설정
- `withCredentials: true` 사용 시 와일드카드(*) 불가, 명시적 origin 지정 필요

### 토큰 재발급 무한 루프
- `isRefreshing` 플래그로 중복 재발급 방지
- `failedQueue`로 대기 중인 요청 관리

## 라이센스

이 프로젝트는 REC::OOK 서비스의 일부입니다.

## 개발자

- 프로젝트: REC::OOK (레시피 추천 서비스)
- 프레임워크: Next.js 15.1 (App Router)
- 아키텍처: Clean Architecture + SOLID Principles
- 작성일: 2026-03-19
