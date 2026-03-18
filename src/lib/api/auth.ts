/**
 * 인증 API 서비스
 * Flutter의 auth_service.dart 대응
 * 로그인, 로그아웃, 토큰 교환, 회원가입 등
 */

import axios from 'axios';
import { apiPost, apiGet, networkError } from './client';
import { API_BASE_URL } from '../config';
import { setAccessToken, clearAllTokens, setUserRole } from '../auth/token';
import { getCodeVerifier, removeCodeVerifier } from '../auth/pkce';
import { ApiResponse, ResponseCode } from '@/types/api';
import {
  LoginRequest,
  LoginResponse,
  UserResponse,
  JoinRequest,
  JoinResponse,
  EmailCheckRequest,
  AccessTokenResponse,
} from '@/types/models';

/**
 * 이메일/비밀번호 로그인
 * @param email - 이메일
 * @param password - 비밀번호
 * @returns 로그인 응답
 */
export async function login(email: string, password: string): Promise<ApiResponse<LoginResponse>> {
  try {
    const request: LoginRequest = { email, password };
    const response = await apiPost<LoginResponse>('/api/auth/login', request);

    // accessToken 저장
    if (response.response.code === ResponseCode.SUCCESS && response.response.data?.accessToken) {
      setAccessToken(response.response.data.accessToken);
    }

    return response;
  } catch (error) {
    console.error('Login error:', error);
    return networkError<LoginResponse>();
  }
}

/**
 * OAuth2 인증 코드를 Access Token으로 교환
 * PKCE code_verifier와 함께 전송
 * @param code - OAuth2 인증 코드
 * @returns 로그인 응답
 */
export async function exchangeCodeForTokens(code: string): Promise<ApiResponse<LoginResponse>> {
  try {
    const codeVerifier = getCodeVerifier();
    if (!codeVerifier) {
      throw new Error('Code verifier not found');
    }

    // Axios 인터셉터 우회를 위해 직접 axios.post 사용
    const response = await axios.post<ApiResponse<LoginResponse>>(
      `${API_BASE_URL}/api/auth/token`,
      {
        code,
        code_verifier: codeVerifier,
      },
      {
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'X-Client-Type': 'WEB',
        },
        withCredentials: true, // HttpOnly 쿠키 수신
      }
    );

    // accessToken 저장
    if (response.data.response.code === ResponseCode.SUCCESS && response.data.response.data?.accessToken) {
      setAccessToken(response.data.response.data.accessToken);
      removeCodeVerifier(); // 사용한 verifier 삭제
    }

    return response.data;
  } catch (error) {
    console.error('Exchange code for tokens error:', error);
    removeCodeVerifier(); // 에러 시에도 verifier 삭제
    return networkError<LoginResponse>();
  }
}

/**
 * 로그아웃
 * @returns 로그아웃 응답
 */
export async function logout(): Promise<ApiResponse<void>> {
  try {
    const response = await apiPost<void>('/api/auth/logout');
    clearAllTokens(); // 모든 토큰 및 사용자 정보 삭제
    return response;
  } catch (error) {
    console.error('Logout error:', error);
    clearAllTokens(); // 에러 시에도 토큰 삭제
    return networkError<void>();
  }
}

/**
 * Access Token 재발급
 * 웹은 refreshToken이 HttpOnly 쿠키로 자동 전송됨
 * @returns Access Token 재발급 응답
 */
export async function refreshAccessToken(): Promise<ApiResponse<AccessTokenResponse>> {
  try {
    // Axios 인터셉터 우회를 위해 직접 axios.post 사용
    const response = await axios.post<ApiResponse<AccessTokenResponse>>(
      `${API_BASE_URL}/api/auth/reissue`,
      {},
      {
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'X-Client-Type': 'WEB',
        },
        withCredentials: true, // HttpOnly 쿠키 자동 전송
      }
    );

    // 새로운 accessToken 저장
    if (response.data.response.code === ResponseCode.SUCCESS && response.data.response.data?.accessToken) {
      setAccessToken(response.data.response.data.accessToken);
    }

    return response.data;
  } catch (error) {
    console.error('Refresh access token error:', error);
    return networkError<AccessTokenResponse>();
  }
}

/**
 * 현재 사용자 정보 조회
 * @returns 사용자 정보 응답
 */
export async function getCurrentUser(): Promise<ApiResponse<UserResponse>> {
  try {
    const response = await apiGet<UserResponse>('/api/user/me');

    // userRole 업데이트
    if (response.response.code === ResponseCode.SUCCESS && response.response.data?.role) {
      setUserRole(response.response.data.role);
    }

    return response;
  } catch (error) {
    console.error('Get current user error:', error);
    return networkError<UserResponse>();
  }
}

/**
 * 이메일 중복 확인
 * @param email - 확인할 이메일
 * @returns 이메일 중복 확인 응답
 */
export async function checkEmail(email: string): Promise<ApiResponse<boolean>> {
  try {
    const request: EmailCheckRequest = { email };
    const response = await apiPost<boolean>('/api/user/email', request);
    return response;
  } catch (error) {
    console.error('Check email error:', error);
    return networkError<boolean>();
  }
}

/**
 * 회원가입
 * @param request - 회원가입 요청 데이터
 * @returns 회원가입 응답
 */
export async function signup(request: JoinRequest): Promise<ApiResponse<JoinResponse>> {
  try {
    const response = await apiPost<JoinResponse>('/api/user', request);
    return response;
  } catch (error) {
    console.error('Signup error:', error);
    return networkError<JoinResponse>();
  }
}
