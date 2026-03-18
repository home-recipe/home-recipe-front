/**
 * 공통 API 클라이언트
 * Flutter의 api_client.dart 대응
 * Axios 기반 HTTP 클라이언트 및 인증 에러 처리
 */

import axios, { AxiosInstance, AxiosError, InternalAxiosRequestConfig } from 'axios';
import { API_BASE_URL } from '../config';
import { getAccessToken, setAccessToken, clearAllTokens } from '../auth/token';
import { ApiResponse, ResponseCode, ResponseCodeType } from '@/types/api';
import { AccessTokenResponse } from '@/types/models';

/** Axios 인스턴스 */
const axiosInstance: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true, // HttpOnly 쿠키 전송을 위해 필수
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json; charset=utf-8',
  },
});

/** 토큰 재발급 진행 중 플래그 */
let isRefreshing = false;

/** 토큰 재발급 대기 큐 */
interface FailedQueueItem {
  resolve: (token: string) => void;
  reject: (error: Error) => void;
}
let failedQueue: FailedQueueItem[] = [];

/**
 * 대기 중인 요청 처리
 * @param error - 에러 객체 (실패 시)
 * @param token - 새로운 Access Token (성공 시)
 */
function processQueue(error: Error | null, token: string | null = null): void {
  failedQueue.forEach((prom) => {
    if (error) {
      prom.reject(error);
    } else if (token) {
      prom.resolve(token);
    }
  });
  failedQueue = [];
}

/**
 * 강제 로그아웃 처리
 * 모든 토큰 삭제 후 로그인 페이지로 리다이렉트
 */
function forceLogout(): void {
  clearAllTokens();
  if (typeof window !== 'undefined') {
    window.location.href = '/login';
  }
}

/**
 * 요청 인터셉터: Authorization 헤더 자동 추가
 */
axiosInstance.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = getAccessToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    // X-Client-Type 헤더 추가
    config.headers['X-Client-Type'] = 'WEB';
    return config;
  },
  (error) => Promise.reject(error)
);

/**
 * 응답 인터셉터: 인증 에러 감지 및 토큰 재발급
 */
axiosInstance.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean };

    // 응답이 있고 ApiResponse 형태인 경우
    if (error.response && error.response.data) {
      const apiResponse = error.response.data as ApiResponse<unknown>;
      const responseCode: ResponseCodeType = apiResponse.response?.code;

      // AUTH_EXPIRED_TOKEN: 토큰 재발급 시도
      if (responseCode === ResponseCode.AUTH_EXPIRED_TOKEN && !originalRequest._retry) {
        if (isRefreshing) {
          // 이미 재발급 중이면 대기 큐에 추가
          return new Promise((resolve, reject) => {
            failedQueue.push({
              resolve: (token: string) => {
                if (originalRequest.headers) {
                  originalRequest.headers.Authorization = `Bearer ${token}`;
                }
                resolve(axiosInstance(originalRequest));
              },
              reject: (err: Error) => {
                reject(err);
              },
            });
          });
        }

        originalRequest._retry = true;
        isRefreshing = true;

        try {
          // 토큰 재발급 API 호출 (웹은 쿠키 자동 전송)
          const response = await axios.post<ApiResponse<AccessTokenResponse>>(
            `${API_BASE_URL}/api/auth/reissue`,
            {},
            {
              withCredentials: true,
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'X-Client-Type': 'WEB',
              },
            }
          );

          const newToken = response.data.response.data?.accessToken;
          if (newToken) {
            setAccessToken(newToken);
            processQueue(null, newToken);

            // 원래 요청 재시도
            if (originalRequest.headers) {
              originalRequest.headers.Authorization = `Bearer ${newToken}`;
            }
            return axiosInstance(originalRequest);
          } else {
            throw new Error('No access token in response');
          }
        } catch (refreshError) {
          processQueue(refreshError as Error, null);
          forceLogout();
          return Promise.reject(refreshError);
        } finally {
          isRefreshing = false;
        }
      }

      // AUTH_NOT_EXIST_TOKEN, AUTH_INVALID_TOKEN: 강제 로그아웃
      if (
        responseCode === ResponseCode.AUTH_NOT_EXIST_TOKEN ||
        responseCode === ResponseCode.AUTH_INVALID_TOKEN
      ) {
        forceLogout();
      }
    }

    return Promise.reject(error);
  }
);

/**
 * GET 요청
 * @param url - 요청 URL
 * @returns API 응답 데이터
 */
export async function apiGet<T>(url: string): Promise<ApiResponse<T>> {
  const response = await axiosInstance.get<ApiResponse<T>>(url);
  return response.data;
}

/**
 * POST 요청
 * @param url - 요청 URL
 * @param data - 요청 데이터
 * @returns API 응답 데이터
 */
export async function apiPost<T>(url: string, data?: unknown): Promise<ApiResponse<T>> {
  const response = await axiosInstance.post<ApiResponse<T>>(url, data);
  return response.data;
}

/**
 * PUT 요청
 * @param url - 요청 URL
 * @param data - 요청 데이터
 * @returns API 응답 데이터
 */
export async function apiPut<T>(url: string, data?: unknown): Promise<ApiResponse<T>> {
  const response = await axiosInstance.put<ApiResponse<T>>(url, data);
  return response.data;
}

/**
 * DELETE 요청
 * @param url - 요청 URL
 * @returns API 응답 데이터
 */
export async function apiDelete<T>(url: string): Promise<ApiResponse<T>> {
  const response = await axiosInstance.delete<ApiResponse<T>>(url);
  return response.data;
}

/**
 * 리스트 조회 GET 요청
 * @param url - 요청 URL
 * @returns API 응답 데이터 (배열)
 */
export async function apiGetList<T>(url: string): Promise<ApiResponse<T[]>> {
  const response = await axiosInstance.get<ApiResponse<T[]>>(url);
  return response.data;
}

/**
 * 네트워크 에러 응답 생성
 * @returns 네트워크 에러 응답
 */
export function networkError<T>(): ApiResponse<T> {
  return {
    code: 500,
    message: 'Network Error',
    response: {
      code: ResponseCode.NETWORK_ERROR,
      data: null,
    },
  };
}

export { forceLogout };
