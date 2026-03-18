# Senior Code Architect Memory for home-recipe-front

## Project Overview
- **Dual Stack**: Flutter web/mobile (legacy) + Next.js App Router (new frontend)
- Korean language UI with English code
- Flutter uses Material 3 design system
- Next.js uses Tailwind CSS with same color palette

## Color System Architecture (Updated 2026-03-03)
**Red Theme Implementation (#f21d1d)**

### Central Color Constants
- Location: `/lib/constants/app_colors.dart`
- All app colors are defined as static const in AppColors class
- **Never hardcode Color values** - always use AppColors constants

### Color Palette
#### Primary Colors
- `AppColors.primaryOrange`: **#F21D1D** (레드 포인트 컬러 - 변경됨)
- `AppColors.primaryGreen`: #19E619

#### Accent Colors
- `AppColors.accentYellow`: #FFEA00 (Material Yellow A700)
- `AppColors.accentPink`: #FF1744 (Material Red A400)

#### Text Colors
- `AppColors.textDark`: #212121 (Material Grey 900)
- `AppColors.textGrey`: #616161 (Material Grey 700)

#### Background Colors
- `AppColors.backgroundWhite`: #FFFFFF
- `AppColors.backgroundLight`: #F5F5F5 (Material Grey 50)
- `AppColors.backgroundBeige`: #F2EFEB

#### Logo & Outline
- `AppColors.logoOutline`: #263238 (Blue Grey 900)

#### Gradient Colors
- REC:: gradient: primaryOrange (#F21D1D) → #FF4444 (변경됨)
- OOK gradient: primaryGreen → gradientGreenEnd (#00BFA5)

### Logo Implementation
- Location: `/lib/widgets/recook_logo.dart`
- Uses gradient effects with ShaderMask
- Two components: RecookLogo (small) and RecookTitle (large)
- Gradient applied separately to "REC::" and "OOK" parts
- **Do not use `const` before AppColors.xxx** - they are already const

### Code Conventions
1. Always import `app_colors.dart` when using colors
2. Use AppColors constants instead of hardcoded Color(0xFFxxxxxx)
3. Text styles in `/lib/constants/app_text_styles.dart` also use AppColors
4. Social login button colors (Google, Kakao) should NOT be changed

### Common Patterns
- Card shadows: Use both primaryGreen and primaryOrange with opacity
- Buttons: primaryOrange for main actions, primaryGreen for secondary
- Hover effects: primaryGreen for non-selected hover states

### Theme Configuration
- Main.dart uses `AppColors.primaryOrange` as seedColor
- Material 3 enabled
- No dark mode implemented

## Navigation Architecture (Updated 2026-03-03)
**AppBar-based Tab Navigation**

### Main Structure
- Location: `/lib/screens/main_navigation.dart`
- **Top AppBar navigation** (not BottomNavigationBar)
- 4 tabs: 홈(0), My(1), 레시피(2), 추천(3)

### Authentication Guard
- Location: `/lib/widgets/auth_guard_dialog.dart`
- Helper function: `showAuthRequiredDialog(context)`
- Shows login required dialog for protected tabs
- Tabs 1,2,3 require login (checked via TokenService.getAccessToken())
- Tab 0 (홈) is always accessible

### Landing Page (Updated 2026-03-05)
- Location: `/lib/screens/landing_page.dart`
- Service introduction page shown on 홈 tab
- Uses animation widgets in `/lib/widgets/landing/`
  - `hero_section.dart`: Main banner with image slider (4s interval, cross-fade)
  - `value_card.dart`: Card with icon, title, description, CTA button
  - `value_proposition_section.dart`: My/추천 기능 소개 (2개 카드)
  - `feature_card.dart`: Feature introduction cards
  - `animated_section.dart`: Scroll-triggered animations

### Landing Page Structure
1. **HeroSection**: Background image slider (assets/front/1.png, 2.png, 3.png)
   - Auto-transitions every 4 seconds with cross-fade
   - Dark overlay (0.4 opacity) for text readability
   - White text with shadow for contrast
   - Height: isWide ? 550 : 400
   - No CTA buttons (removed in favor of ValuePropositionSection)

2. **ValuePropositionSection**: Two feature cards
   - My 카드: primaryGreen color, navigates to tab 1
   - 추천 카드: primaryOrange color, navigates to tab 3
   - Responsive: Row (isWide) / Column (mobile)
   - Hover effect: lift up on hover

3. **FeatureSection**: General feature introduction (3 cards)
   - Existing design maintained

### App Entry Point
- main.dart initialRoute: MainNavigation(initialIndex: 0)
- Login successful: Navigate to MainNavigation(initialIndex: 0)
- LoginPage is now a separate route, not the initial screen

## Image Assets
- Landing page images: `assets/front/1.png`, `2.png`, `3.png`
- Assets folder already registered in pubspec.yaml (`assets/`)

## Important Notes
- Korean text in UI, English in code/comments
- All code must have Korean comments (project rule)
- Use `fontFamily: 'NanumGothicCoding-Regular'` with `letterSpacing: 0.5`
- LogoutHelper.handleLogout(context) for logout functionality
- Social login uses PKCE flow (PkceService)

## Animation Patterns
- Timer.periodic for interval-based animations (remember to cancel in dispose)
- AnimatedOpacity for cross-fade effects
- AnimatedContainer for hover effects (transform: Matrix4.translationValues)
- Always check `mounted` before setState in async callbacks
- Dispose all controllers and timers in dispose method

## Next.js Frontend Architecture (Added 2026-03-19)

### Project Structure
- Location: `/src/app/` (App Router)
- Shared layout: `src/app/layout.tsx` with fixed Header
- Global styles: `src/app/globals.css` (CSS variables match Flutter colors)
- Components: `src/components/` (auth, layout, etc.)

### Layout System
- **Fixed Header + Full Height Body** pattern
- `layout.tsx`: Header (fixed) + main (flex-1)
- Body element: `h-screen flex flex-col overflow-hidden`
- Main element: `flex-1 overflow-hidden` (takes remaining height)

### Header Component
- Location: `/src/components/layout/Header.tsx`
- White background (`bg-white shadow-sm`)
- Left: "Re:Cook" text logo (black)
- Right: 회원가입 button (ghost style) when logged out
- Uses `useAuth` hook for authentication state

### Home Page (Fullscreen Image Slider)
- Location: `/src/app/page.tsx`
- **Fullscreen carousel** with 3 images from `/assets/front/`
- Image sources: `/assets/front/1.png`, `2.png`, `3.png`
  - **Important**: Images must be in `public/assets/front/` (Next.js static serving)
  - Copy from Flutter `assets/front/` if needed: `cp assets/front/*.png public/assets/front/`
- Slide interval: 6 seconds
- Fade duration: 1500ms (very slow and smooth)
- Text overlay: centered, white text with dark shadow
- Each slide has different title + description
- CTA buttons: "시작하기" (red), "로그인" (white/blur)
- Slide indicators: bottom center, clickable dots

### Animation Implementation
- Uses React hooks: `useState`, `useEffect`
- No external slider libraries (bundle size optimization)
- Transition timing:
  - `setIsTransitioning(true)` → fade out
  - After 800ms → change slide index
  - `setIsTransitioning(false)` → fade in
- CSS transitions: `duration-[1500ms]` for smooth fade
- Staggered text animations: `delay-100`, `delay-200` for title/description/buttons

### CSS Variables (globals.css)
- Matches Flutter `app_colors.dart` palette
- Primary: `--color-primary-orange` (#f21d1d), `--color-primary-green` (#19e619)
- Gradient: REC:: (orange→#ff4444), OOK (green→#00bfa5)
- Font: 'NanumGothicCoding' with `letter-spacing: 0.5px`
- Overflow hidden on html/body for fullscreen effect

### Image Asset Workflow
1. Flutter images: `assets/front/*.png` (committed to repo)
2. Next.js images: `public/assets/front/*.png` (copied from Flutter)
3. Access in code: `/assets/front/1.png` (public/ is root in Next.js)
4. **Do not modify Flutter assets** - only copy to public/

### Code Conventions (Next.js)
- All code comments in Korean (project rule)
- TypeScript with strict typing
- Tailwind CSS for styling (no CSS modules)
- Client components: `'use client'` directive
- Auth hook: `useAuth()` from `@/hooks/useAuth`
- Router: `useRouter()` from `next/navigation`
