/**
 * 루트 레이아웃
 * 전체 앱의 레이아웃 및 전역 설정
 */

import type { Metadata } from 'next';
import { AuthProvider } from '@/components/auth/AuthProvider';
import Header from '@/components/layout/Header';
import './globals.css';

export const metadata: Metadata = {
  title: 'REC::OOK - 홈 레시피 추천',
  description: 'AI 기반 맞춤형 레시피 추천 서비스',
  keywords: ['레시피', '요리', '추천', 'AI', '집밥'],
};

/**
 * 루트 레이아웃 컴포넌트
 * Header(고정) + Body 구조
 */
export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko">
      <head>
        {/* Google Fonts: Nanum Gothic Coding */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Nanum+Gothic+Coding:wght@400;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="h-screen flex flex-col overflow-hidden">
        <AuthProvider>
          {/* 고정 헤더 */}
          <Header />
          {/* 메인 콘텐츠 영역 - 나머지 높이를 모두 차지 */}
          <main className="flex-1 overflow-hidden">
            {children}
          </main>
        </AuthProvider>
      </body>
    </html>
  );
}
