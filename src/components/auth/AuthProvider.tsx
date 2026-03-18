/**
 * 인증 Context Provider
 * 전역 인증 상태 관리 및 인증 관련 함수 제공
 */

'use client';

import React, { createContext, useState, useEffect, useCallback, ReactNode } from 'react';
import { UserResponse } from '@/types/models';
import { ResponseCode } from '@/types/api';
import * as authApi from '@/lib/api/auth';
import { getAccessToken } from '@/lib/auth/token';

/** 인증 Context 타입 */
interface AuthContextType {
  /** 인증 여부 */
  isAuthenticated: boolean;
  /** 현재 사용자 정보 */
  user: UserResponse | null;
  /** 로딩 상태 */
  loading: boolean;
  /** 로그인 함수 */
  login: (email: string, password: string) => Promise<boolean>;
  /** 로그아웃 함수 */
  logout: () => Promise<void>;
  /** 인증 상태 확인 함수 */
  checkAuth: () => Promise<void>;
}

/** 인증 Context */
export const AuthContext = createContext<AuthContextType | undefined>(undefined);

/** AuthProvider Props */
interface AuthProviderProps {
  children: ReactNode;
}

/**
 * AuthProvider 컴포넌트
 * 전역 인증 상태를 관리하고 자식 컴포넌트에 제공
 */
export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<UserResponse | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);

  /**
   * 인증 상태 확인
   * Access Token이 있으면 사용자 정보 조회
   */
  const checkAuth = useCallback(async () => {
    const token = getAccessToken();

    if (!token) {
      setIsAuthenticated(false);
      setUser(null);
      setLoading(false);
      return;
    }

    try {
      const response = await authApi.getCurrentUser();

      if (response.response.code === ResponseCode.SUCCESS && response.response.data) {
        setUser(response.response.data);
        setIsAuthenticated(true);
      } else {
        setIsAuthenticated(false);
        setUser(null);
      }
    } catch (error) {
      console.error('Check auth error:', error);
      setIsAuthenticated(false);
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, []);

  /**
   * 로그인
   * @param email - 이메일
   * @param password - 비밀번호
   * @returns 로그인 성공 여부
   */
  const login = useCallback(async (email: string, password: string): Promise<boolean> => {
    try {
      const response = await authApi.login(email, password);

      if (response.response.code === ResponseCode.SUCCESS && response.response.data?.accessToken) {
        // 로그인 성공 후 사용자 정보 조회
        await checkAuth();
        return true;
      }

      return false;
    } catch (error) {
      console.error('Login error:', error);
      return false;
    }
  }, [checkAuth]);

  /**
   * 로그아웃
   */
  const logout = useCallback(async () => {
    try {
      await authApi.logout();
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setIsAuthenticated(false);
      setUser(null);
    }
  }, []);

  /**
   * 컴포넌트 마운트 시 인증 상태 확인
   */
  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  const value: AuthContextType = {
    isAuthenticated,
    user,
    loading,
    login,
    logout,
    checkAuth,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
