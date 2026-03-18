/**
 * PKCE (Proof Key for Code Exchange) 서비스
 * Flutter의 pkce_service.dart 대응
 * OAuth2 인증 시 code_verifier 및 code_challenge 생성
 */

// localStorage 키
const CODE_VERIFIER_KEY = 'pkce_code_verifier';

// 메모리 폴백
let memoryCodeVerifier: string | null = null;

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
 * Code Verifier 생성
 * 128자의 무작위 문자열 생성 (A-Za-z0-9-._~)
 * @returns 생성된 Code Verifier
 */
export function generateCodeVerifier(): string {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  const length = 128;
  const randomValues = new Uint8Array(length);
  crypto.getRandomValues(randomValues);

  let result = '';
  for (let i = 0; i < length; i++) {
    result += charset[randomValues[i] % charset.length];
  }

  return result;
}

/**
 * Base64 URL 인코딩 (패딩 제거)
 * @param buffer - 인코딩할 ArrayBuffer
 * @returns Base64 URL 인코딩된 문자열
 */
function base64UrlEncode(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

/**
 * Code Challenge 생성
 * Code Verifier를 SHA-256 해시 후 Base64 URL 인코딩
 * @param verifier - Code Verifier
 * @returns Code Challenge (Promise)
 */
export async function generateCodeChallenge(verifier: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  return base64UrlEncode(hashBuffer);
}

/**
 * Code Verifier 저장
 * @param verifier - 저장할 Code Verifier
 */
export function saveCodeVerifier(verifier: string): void {
  if (isLocalStorageAvailable()) {
    window.localStorage.setItem(CODE_VERIFIER_KEY, verifier);
  } else {
    memoryCodeVerifier = verifier;
  }
}

/**
 * Code Verifier 조회
 * @returns Code Verifier 또는 null
 */
export function getCodeVerifier(): string | null {
  if (isLocalStorageAvailable()) {
    return window.localStorage.getItem(CODE_VERIFIER_KEY);
  }
  return memoryCodeVerifier;
}

/**
 * Code Verifier 삭제
 */
export function removeCodeVerifier(): void {
  if (isLocalStorageAvailable()) {
    window.localStorage.removeItem(CODE_VERIFIER_KEY);
  } else {
    memoryCodeVerifier = null;
  }
}
