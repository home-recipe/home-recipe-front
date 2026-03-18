/**
 * 회원가입 페이지
 * 이메일, 비밀번호, 이름 입력 및 이메일 중복 확인
 */

'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { checkEmail, signup } from '@/lib/api/auth';
import { ResponseCode } from '@/types/api';
import { JoinRequest } from '@/types/models';

/**
 * 회원가입 페이지 컴포넌트
 */
export default function SignupPage() {
  const router = useRouter();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [passwordConfirm, setPasswordConfirm] = useState('');
  const [name, setName] = useState('');
  const [emailChecked, setEmailChecked] = useState(false);
  const [emailAvailable, setEmailAvailable] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  /**
   * 이메일 중복 확인
   */
  const handleCheckEmail = async () => {
    if (!email) {
      setError('이메일을 입력해주세요.');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');

    try {
      const response = await checkEmail(email);

      if (response.response.code === ResponseCode.SUCCESS) {
        const exists = response.response.data;

        if (exists) {
          setError('이미 사용 중인 이메일입니다.');
          setEmailAvailable(false);
          setEmailChecked(true);
        } else {
          setSuccess('사용 가능한 이메일입니다.');
          setEmailAvailable(true);
          setEmailChecked(true);
        }
      } else {
        setError('이메일 확인 중 오류가 발생했습니다.');
        setEmailChecked(false);
      }
    } catch (err) {
      console.error('Check email error:', err);
      setError('이메일 확인 중 오류가 발생했습니다.');
      setEmailChecked(false);
    } finally {
      setLoading(false);
    }
  };

  /**
   * 회원가입 처리
   */
  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    // 유효성 검사
    if (!emailChecked || !emailAvailable) {
      setError('이메일 중복 확인을 해주세요.');
      return;
    }

    if (password !== passwordConfirm) {
      setError('비밀번호가 일치하지 않습니다.');
      return;
    }

    if (password.length < 8) {
      setError('비밀번호는 8자 이상이어야 합니다.');
      return;
    }

    setLoading(true);

    try {
      const request: JoinRequest = {
        email,
        password,
        name,
      };

      const response = await signup(request);

      if (response.response.code === ResponseCode.SUCCESS) {
        setSuccess('회원가입이 완료되었습니다. 로그인 페이지로 이동합니다.');
        setTimeout(() => {
          router.push('/login');
        }, 1500);
      } else {
        setError(response.message || '회원가입에 실패했습니다.');
      }
    } catch (err) {
      console.error('Signup error:', err);
      setError('회원가입 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  /**
   * 이메일 변경 시 중복 확인 초기화
   */
  const handleEmailChange = (value: string) => {
    setEmail(value);
    setEmailChecked(false);
    setEmailAvailable(false);
    setError('');
    setSuccess('');
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
          <p className="text-[#616161] mt-2">회원가입</p>
        </div>

        {/* 에러 메시지 */}
        {error && (
          <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
            {error}
          </div>
        )}

        {/* 성공 메시지 */}
        {success && (
          <div className="mb-4 p-3 bg-green-100 border border-green-400 text-green-700 rounded">
            {success}
          </div>
        )}

        {/* 회원가입 폼 */}
        <form onSubmit={handleSignup} className="space-y-4">
          {/* 이메일 */}
          <div>
            <label htmlFor="email" className="block text-sm font-medium mb-1">
              이메일
            </label>
            <div className="flex gap-2">
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => handleEmailChange(e.target.value)}
                required
                className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#f21d1d]"
                placeholder="example@email.com"
              />
              <button
                type="button"
                onClick={handleCheckEmail}
                disabled={loading || !email}
                className="px-4 py-2 bg-[#19e619] text-white rounded-lg hover:opacity-90 transition disabled:opacity-50 disabled:cursor-not-allowed whitespace-nowrap"
              >
                중복 확인
              </button>
            </div>
          </div>

          {/* 이름 */}
          <div>
            <label htmlFor="name" className="block text-sm font-medium mb-1">
              이름
            </label>
            <input
              id="name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#f21d1d]"
              placeholder="홍길동"
            />
          </div>

          {/* 비밀번호 */}
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
              placeholder="8자 이상 입력하세요"
            />
          </div>

          {/* 비밀번호 확인 */}
          <div>
            <label htmlFor="passwordConfirm" className="block text-sm font-medium mb-1">
              비밀번호 확인
            </label>
            <input
              id="passwordConfirm"
              type="password"
              value={passwordConfirm}
              onChange={(e) => setPasswordConfirm(e.target.value)}
              required
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#f21d1d]"
              placeholder="비밀번호를 다시 입력하세요"
            />
          </div>

          {/* 회원가입 버튼 */}
          <button
            type="submit"
            disabled={loading || !emailChecked || !emailAvailable}
            className="w-full py-3 bg-[#f21d1d] text-white rounded-lg hover:opacity-90 transition disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? '처리 중...' : '회원가입'}
          </button>
        </form>

        {/* 로그인 링크 */}
        <div className="mt-6 text-center">
          <p className="text-sm text-[#616161]">
            이미 계정이 있으신가요?{' '}
            <button
              onClick={() => router.push('/login')}
              className="text-[#f21d1d] hover:underline font-medium"
            >
              로그인
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
