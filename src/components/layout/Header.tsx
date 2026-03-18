/**
 * 고정 헤더 컴포넌트
 * 모든 페이지에서 공유되는 상단 네비게이션
 */

'use client';

import Link from 'next/link';
import { useAuth } from '@/hooks/useAuth';

/**
 * Header 컴포넌트
 * 왼쪽: Re:Cook 브랜드 로고 (강조 색상 적용)
 * 오른쪽: 로그인 전 - 로그인 + 회원가입, 로그인 후 - 네비게이션
 */
export default function Header() {
  const { isAuthenticated } = useAuth();

  return (
    <header className="bg-white shadow-sm z-50">
      <div className="container mx-auto px-6 py-4">
        <div className="flex justify-between items-center">
          {/* 브랜드 로고 - 'Cook'에 강조 색상 적용 */}
          <Link href="/" className="hover:opacity-80 transition">
            <span className="text-2xl md:text-3xl font-black tracking-tighter text-black">
              Re:<span className="text-[#f21d1d]">Cook</span>
            </span>
          </Link>

          {/* 네비게이션 */}
          <nav className="flex items-center gap-3">
            {isAuthenticated ? (
              <>
                {/* 로그인 후 네비게이션 */}
                <Link
                  href="/recipes"
                  className="text-sm text-black hover:text-[#f21d1d] transition font-medium"
                >
                  레시피
                </Link>
                <Link
                  href="/my"
                  className="text-sm text-black hover:text-[#f21d1d] transition font-medium"
                >
                  내 정보
                </Link>
              </>
            ) : (
              <>
                {/* 로그인 버튼 - 텍스트 스타일 */}
                <Link
                  href="/login"
                  className="text-sm text-black hover:text-[#f21d1d] transition font-medium"
                >
                  로그인
                </Link>
                {/* 회원가입 버튼 - 테두리 스타일 */}
                <Link
                  href="/signup"
                  className="text-sm text-black border border-black rounded-full px-4 py-1.5
                    hover:bg-black hover:text-white transition-all font-medium"
                >
                  회원가입
                </Link>
              </>
            )}
          </nav>
        </div>
      </div>
    </header>
  );
}
