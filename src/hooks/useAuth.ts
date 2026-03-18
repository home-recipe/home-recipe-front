/**
 * 인증 커스텀 Hook
 * 전역 인증 상태 관리 및 인증 관련 함수 제공
 */

import { useContext } from 'react';
import { AuthContext } from '@/components/auth/AuthProvider';

/**
 * 인증 Hook
 * AuthProvider로 감싸진 컴포넌트에서만 사용 가능
 * @returns 인증 상태 및 함수
 */
export function useAuth() {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }

  return context;
}
