/**
 * 환경 설정 관리
 * API 서버 및 OAuth 서버 URL을 환경 변수로 관리
 */

/** API 기본 URL */
export const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';

/** OAuth 서버 URL */
export const OAUTH_SERVER_URL = process.env.NEXT_PUBLIC_OAUTH_SERVER_URL || 'https://recook-server.site';

/**
 * Google OAuth2 인증 URL 생성
 * @param codeChallenge - PKCE code challenge
 * @returns Google OAuth2 인증 URL
 */
export function googleOAuthUrl(codeChallenge: string): string {
  return `${OAUTH_SERVER_URL}/oauth2/authorization/google?state=WEB&challenge=${codeChallenge}`;
}

/**
 * Kakao OAuth2 인증 URL 생성
 * @param codeChallenge - PKCE code challenge
 * @returns Kakao OAuth2 인증 URL
 */
export function kakaoOAuthUrl(codeChallenge: string): string {
  return `${OAUTH_SERVER_URL}/oauth2/authorization/kakao?state=WEB&challenge=${codeChallenge}`;
}
