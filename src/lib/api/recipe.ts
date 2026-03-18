/**
 * 레시피 API 서비스
 * 레시피 생성, 조회 등
 */

import { apiPost, apiGet, apiGetList, networkError } from './client';
import { API_BASE_URL } from '../config';
import { ApiResponse, ResponseCode } from '@/types/api';
import { RecipesResponse } from '@/types/models';

/**
 * 레시피 생성 (AI 생성 요청)
 * @returns 레시피 생성 응답
 */
export async function createRecipes(): Promise<ApiResponse<RecipesResponse>> {
  try {
    const response = await apiPost<RecipesResponse>('/api/recipes');
    return response;
  } catch (error) {
    console.error('Create recipes error:', error);
    return networkError<RecipesResponse>();
  }
}

/**
 * 레시피 ID로 조회
 * @param id - 레시피 ID
 * @returns 레시피 응답
 */
export async function getRecipeById(id: string): Promise<ApiResponse<RecipesResponse>> {
  try {
    const response = await apiGet<RecipesResponse>(`/api/recipes/${id}`);
    return response;
  } catch (error) {
    console.error('Get recipe by id error:', error);
    return networkError<RecipesResponse>();
  }
}

/**
 * 레시피 목록 조회
 * @returns 레시피 목록 응답
 */
export async function getRecipes(): Promise<ApiResponse<RecipesResponse[]>> {
  try {
    const response = await apiGetList<RecipesResponse>('/api/recipes');
    return response;
  } catch (error) {
    console.error('Get recipes error:', error);
    return networkError<RecipesResponse[]>();
  }
}

/**
 * SSR용: 레시피 ID로 조회 (서버 컴포넌트용)
 * Axios 인스턴스를 사용하지 않고 직접 fetch 사용
 * @param id - 레시피 ID
 * @returns 레시피 응답 또는 null
 */
export async function fetchRecipeById(id: string): Promise<RecipesResponse | null> {
  try {
    const response = await fetch(`${API_BASE_URL}/api/recipes/${id}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'X-Client-Type': 'WEB',
      },
      cache: 'no-store', // 항상 최신 데이터 가져오기
    });

    if (!response.ok) {
      console.error('Fetch recipe by id failed:', response.statusText);
      return null;
    }

    const apiResponse: ApiResponse<RecipesResponse> = await response.json();

    if (apiResponse.response.code === ResponseCode.SUCCESS && apiResponse.response.data) {
      return apiResponse.response.data;
    }

    return null;
  } catch (error) {
    console.error('Fetch recipe by id error:', error);
    return null;
  }
}
