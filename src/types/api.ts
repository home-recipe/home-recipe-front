/**
 * API 공통 타입 정의
 * Flutter의 api_response.dart 대응
 */

/** API 공통 응답 타입 */
export interface ApiResponse<T> {
  code: number;
  message: string;
  response: ResponseDetail<T>;
}

/** 응답 상세 */
export interface ResponseDetail<T> {
  code: string;
  data: T | null;
}

/** 비즈니스 응답 코드 */
export const ResponseCode = {
  SUCCESS: 'SUCCESS',
  AUTH_EXPIRED_TOKEN: 'AUTH_EXPIRED_TOKEN',
  AUTH_NOT_EXIST_TOKEN: 'AUTH_NOT_EXIST_TOKEN',
  AUTH_INVALID_TOKEN: 'AUTH_INVALID_TOKEN',
  NETWORK_ERROR: 'NETWORK_ERROR',
} as const;

/** 응답 코드 타입 */
export type ResponseCodeType = typeof ResponseCode[keyof typeof ResponseCode];
