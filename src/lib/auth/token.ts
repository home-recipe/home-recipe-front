/**
 * 토큰 관리 서비스
 * Flutter의 token_service.dart 대응
 * localStorage를 사용하여 accessToken과 userRole 관리
 * refreshToken은 서버가 HttpOnly 쿠키로 관리하므로 클라이언트에서 저장하지 않음
 */

// localStorage 키
const ACCESS_TOKEN_KEY = 'access_token';
const USER_ROLE_KEY = 'user_role';

// 메모리 폴백 (SSR 또는 localStorage 접근 불가 시)
let memoryAccessToken: string | null = null;
let memoryUserRole: string | null = null;

/**
 * localStorage 사용 가능 여부 확인
 * @returns localStorage 사용 가능 여부
 */
function isLocalStorageAvailable(): boolean {
  if (typeof window === 'undefined') return false;
  try {
    const test = '__storage_test__';
    window.localStorage.setItem(test, test);
    window.localStorage.removeItem(test);
    return true;
  } catch {
    return false;
  }
}

/**
 * Access Token 저장
 * @param token - 저장할 Access Token
 */
export function setAccessToken(token: string): void {
  if (isLocalStorageAvailable()) {
    window.localStorage.setItem(ACCESS_TOKEN_KEY, token);
  } else {
    memoryAccessToken = token;
  }
}

/**
 * Access Token 조회
 * @returns Access Token 또는 null
 */
export function getAccessToken(): string | null {
  if (isLocalStorageAvailable()) {
    return window.localStorage.getItem(ACCESS_TOKEN_KEY);
  }
  return memoryAccessToken;
}

/**
 * Access Token 삭제
 */
export function removeAccessToken(): void {
  if (isLocalStorageAvailable()) {
    window.localStorage.removeItem(ACCESS_TOKEN_KEY);
  } else {
    memoryAccessToken = null;
  }
}

/**
 * User Role 저장
 * @param role - 사용자 역할
 */
export function setUserRole(role: string): void {
  if (isLocalStorageAvailable()) {
    window.localStorage.setItem(USER_ROLE_KEY, role);
  } else {
    memoryUserRole = role;
  }
}

/**
 * User Role 조회
 * @returns User Role 또는 null
 */
export function getUserRole(): string | null {
  if (isLocalStorageAvailable()) {
    return window.localStorage.getItem(USER_ROLE_KEY);
  }
  return memoryUserRole;
}

/**
 * User Role 삭제
 */
export function removeUserRole(): void {
  if (isLocalStorageAvailable()) {
    window.localStorage.removeItem(USER_ROLE_KEY);
  } else {
    memoryUserRole = null;
  }
}

/**
 * 모든 토큰 및 사용자 정보 삭제
 */
export function clearAllTokens(): void {
  removeAccessToken();
  removeUserRole();
}
