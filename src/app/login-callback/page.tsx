/**
 * 로그인 콜백 페이지
 * OAuth2 인증 코드를 Access Token으로 교환
 */

'use client';

import { useEffect, useState, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { exchangeCodeForTokens } from '@/lib/api/auth';
import { ResponseCode } from '@/types/api';

/**
 * 로그인 콜백 처리 컴포넌트
 */
function LoginCallbackContent() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const handleCallback = async () => {
      try {
        // URL에서 code 파라미터 추출
        const code = searchParams.get('code');
        const accessToken = searchParams.get('accessToken'); // 구버전 서버 감지

        // 구버전 서버 경고
        if (accessToken) {
          setError('구버전 서버가 감지되었습니다. URL에 accessToken이 노출되고 있습니다. 보안상 위험할 수 있습니다.');
          setLoading(false);
          return;
        }

        if (!code) {
          setError('인증 코드가 없습니다.');
          setLoading(false);
          return;
        }

        // 인증 코드를 Access Token으로 교환
        const response = await exchangeCodeForTokens(code);

        if (response.response.code === ResponseCode.SUCCESS && response.response.data?.accessToken) {
          // 로그인 성공: 홈으로 리다이렉트
          router.push('/');
        } else {
          setError(response.message || '로그인에 실패했습니다.');
          setLoading(false);
        }
      } catch (err) {
        console.error('Login callback error:', err);
        setError('로그인 처리 중 오류가 발생했습니다.');
        setLoading(false);
      }
    };

    handleCallback();
  }, [searchParams, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-b from-white to-[#f5f5f5]">
        <div className="spinner mb-4"></div>
        <p className="text-xl text-[#616161]">로그인 처리 중...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-b from-white to-[#f5f5f5]">
        <div className="w-full max-w-md p-8 bg-white rounded-lg shadow-lg text-center">
          <div className="text-4xl mb-4">⚠️</div>
          <h2 className="text-2xl font-bold mb-4">로그인 실패</h2>
          <p className="text-[#616161] mb-6">{error}</p>
          <button
            onClick={() => router.push('/login')}
            className="px-6 py-3 bg-[#f21d1d] text-white rounded-lg hover:opacity-90 transition"
          >
            로그인 화면으로 돌아가기
          </button>
        </div>
      </div>
    );
  }

  return null;
}

/**
 * 로그인 콜백 페이지
 * Suspense로 감싸서 useSearchParams 사용
 */
export default function LoginCallbackPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center">
        <div className="spinner"></div>
      </div>
    }>
      <LoginCallbackContent />
    </Suspense>
  );
}
