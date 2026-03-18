/**
 * 로그인 페이지
 * 이메일/비밀번호 로그인 및 소셜 로그인 (Google, Kakao)
 */

'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/useAuth';
import { generateCodeVerifier, generateCodeChallenge, saveCodeVerifier } from '@/lib/auth/pkce';
import { googleOAuthUrl, kakaoOAuthUrl } from '@/lib/config';

/**
 * 로그인 페이지 컴포넌트
 */
export default function LoginPage() {
  const router = useRouter();
  const { login } = useAuth();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  /**
   * 이메일/비밀번호 로그인 처리
   */
  const handleEmailLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const success = await login(email, password);

      if (success) {
        router.push('/');
      } else {
        setError('이메일 또는 비밀번호가 올바르지 않습니다.');
      }
    } catch (err) {
      console.error('Login error:', err);
      setError('로그인 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  /**
   * 소셜 로그인 처리 (Google, Kakao)
   * PKCE 흐름 시작
   */
  const handleSocialLogin = async (provider: 'google' | 'kakao') => {
    try {
      // Code Verifier 생성 및 저장
      const codeVerifier = generateCodeVerifier();
      saveCodeVerifier(codeVerifier);

      // Code Challenge 생성
      const codeChallenge = await generateCodeChallenge(codeVerifier);

      // OAuth2 인증 URL로 리다이렉트
      const authUrl = provider === 'google'
        ? googleOAuthUrl(codeChallenge)
        : kakaoOAuthUrl(codeChallenge);

      window.location.href = authUrl;
    } catch (err) {
      console.error('Social login error:', err);
      setError('소셜 로그인 중 오류가 발생했습니다.');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-b from-white to-[#f5f5f5]">
      <div className="w-full max-w-md p-8 bg-white rounded-lg shadow-lg">
        {/* 로고 */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold">
            <span className="gradient-text-rec">REC::</span>
            <span className="gradient-text-ook">OOK</span>
          </h1>
          <p className="text-[#616161] mt-2">로그인하여 시작하세요</p>
        </div>

        {/* 에러 메시지 */}
        {error && (
          <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
            {error}
          </div>
        )}

        {/* 이메일/비밀번호 로그인 폼 */}
        <form onSubmit={handleEmailLogin} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm font-medium mb-1">
              이메일
            </label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#f21d1d]"
              placeholder="example@email.com"
            />
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-medium mb-1">
              비밀번호
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#f21d1d]"
              placeholder="비밀번호를 입력하세요"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 bg-[#f21d1d] text-white rounded-lg hover:opacity-90 transition disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? '로그인 중...' : '로그인'}
          </button>
        </form>

        {/* 구분선 */}
        <div className="my-6 flex items-center">
          <div className="flex-1 border-t border-gray-300"></div>
          <span className="px-4 text-sm text-[#616161]">또는</span>
          <div className="flex-1 border-t border-gray-300"></div>
        </div>

        {/* 소셜 로그인 버튼 */}
        <div className="space-y-3">
          <button
            onClick={() => handleSocialLogin('google')}
            className="w-full py-3 bg-white border-2 border-gray-300 rounded-lg hover:bg-gray-50 transition flex items-center justify-center"
          >
            <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24">
              <path
                fill="#4285F4"
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              />
              <path
                fill="#34A853"
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              />
              <path
                fill="#FBBC05"
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
              />
              <path
                fill="#EA4335"
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
              />
            </svg>
            Google로 로그인
          </button>

          <button
            onClick={() => handleSocialLogin('kakao')}
            className="w-full py-3 bg-[#FEE500] rounded-lg hover:opacity-90 transition flex items-center justify-center"
          >
            <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24">
              <path
                fill="#000000"
                d="M12 3C6.477 3 2 6.477 2 10.75c0 2.894 2.014 5.433 5.013 6.858l-1.315 4.826c-.089.328.256.594.558.426l5.126-3.017c.2.009.403.014.618.014 5.523 0 10-3.477 10-7.75S17.523 3 12 3z"
              />
            </svg>
            카카오로 로그인
          </button>
        </div>

        {/* 회원가입 링크 */}
        <div className="mt-6 text-center">
          <p className="text-sm text-[#616161]">
            계정이 없으신가요?{' '}
            <button
              onClick={() => router.push('/signup')}
              className="text-[#f21d1d] hover:underline font-medium"
            >
              회원가입
            </button>
          </p>
        </div>

        {/* 홈으로 돌아가기 */}
        <div className="mt-4 text-center">
          <button
            onClick={() => router.push('/')}
            className="text-sm text-[#616161] hover:text-[#f21d1d]"
          >
            홈으로 돌아가기
          </button>
        </div>
      </div>
    </div>
  );
}
