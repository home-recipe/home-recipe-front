/**
 * 데이터 모델 타입 정의
 * Flutter의 models/ 디렉토리 대응
 */

/** 로그인 요청 */
export interface LoginRequest {
  email: string;
  password: string;
}

/** 로그인 응답 */
export interface LoginResponse {
  accessToken: string;
  refreshToken?: string;
}

/** Access Token 재발급 응답 */
export interface AccessTokenResponse {
  accessToken: string;
}

/** 사용자 정보 응답 */
export interface UserResponse {
  id: number;
  email: string;
  name: string;
  role: string;
  profileImageUrl?: string;
}

/** 회원가입 요청 */
export interface JoinRequest {
  email: string;
  password: string;
  name: string;
}

/** 회원가입 응답 */
export interface JoinResponse {
  id: number;
  email: string;
  name: string;
}

/** 레시피 결정 유형 */
export type RecipeDecision = 'COOK' | 'DELIVERY';

/** 레시피 응답 */
export interface RecipesResponse {
  decision: RecipeDecision;
  reason: string;
  recipes: RecipeDetail[] | null;
}

/** 레시피 상세 */
export interface RecipeDetail {
  recipeName: string;
  ingredients: string[];
  steps: string[];
  imageUrl?: string;
}

/** 이메일 중복 확인 요청 */
export interface EmailCheckRequest {
  email: string;
}

/** 이메일 중복 확인 응답 */
export interface EmailCheckResponse {
  exists: boolean;
}
