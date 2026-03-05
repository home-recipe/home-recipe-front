# Senior Code Architect Memory for home-recipe-front

## Project Overview
- Flutter web/mobile application (REC::OOK)
- Korean language UI with English code
- Uses Material 3 design system

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
