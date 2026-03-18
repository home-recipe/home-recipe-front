/**
 * 레시피 목록 페이지
 * 사용자가 생성한 레시피 목록 조회 및 표시
 */

'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/useAuth';
import { getRecipes, createRecipes } from '@/lib/api/recipe';
import { ResponseCode } from '@/types/api';
import { RecipesResponse } from '@/types/models';

/**
 * 레시피 목록 페이지 컴포넌트
 */
export default function RecipesPage() {
  const router = useRouter();
  const { isAuthenticated, loading: authLoading } = useAuth();

  const [recipes, setRecipes] = useState<RecipesResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState('');

  /**
   * 레시피 목록 조회
   */
  const fetchRecipes = async () => {
    setLoading(true);
    setError('');

    try {
      const response = await getRecipes();

      if (response.response.code === ResponseCode.SUCCESS && response.response.data) {
        setRecipes(response.response.data);
      } else {
        setError('레시피를 불러올 수 없습니다.');
      }
    } catch (err) {
      console.error('Fetch recipes error:', err);
      setError('레시피를 불러오는 중 오류가 발생했습니다.');
    } finally {
      setLoading(false);
    }
  };

  /**
   * 새 레시피 생성
   */
  const handleCreateRecipe = async () => {
    setCreating(true);
    setError('');

    try {
      const response = await createRecipes();

      if (response.response.code === ResponseCode.SUCCESS && response.response.data) {
        // 레시피 생성 성공: 목록 새로고침
        await fetchRecipes();
      } else {
        setError(response.message || '레시피 생성에 실패했습니다.');
      }
    } catch (err) {
      console.error('Create recipe error:', err);
      setError('레시피 생성 중 오류가 발생했습니다.');
    } finally {
      setCreating(false);
    }
  };

  /**
   * 컴포넌트 마운트 시 인증 확인 및 레시피 목록 조회
   */
  useEffect(() => {
    if (!authLoading) {
      if (!isAuthenticated) {
        router.push('/login');
      } else {
        fetchRecipes();
      }
    }
  }, [authLoading, isAuthenticated, router]);

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="spinner"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-[#f5f5f5]">
      {/* 헤더 */}
      <header className="container mx-auto px-4 py-6">
        <div className="flex justify-between items-center">
          <h1
            className="text-3xl font-bold cursor-pointer"
            onClick={() => router.push('/')}
          >
            <span className="gradient-text-rec">REC::</span>
            <span className="gradient-text-ook">OOK</span>
          </h1>
          <button
            onClick={() => router.push('/')}
            className="px-6 py-2 text-[#616161] hover:text-[#f21d1d] transition"
          >
            홈으로
          </button>
        </div>
      </header>

      {/* 메인 콘텐츠 */}
      <main className="container mx-auto px-4 py-8">
        <div className="flex justify-between items-center mb-8">
          <h2 className="text-3xl font-bold">내 레시피</h2>
          <button
            onClick={handleCreateRecipe}
            disabled={creating}
            className="px-6 py-3 bg-[#f21d1d] text-white rounded-lg hover:opacity-90 transition disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {creating ? '생성 중...' : '새 레시피 생성'}
          </button>
        </div>

        {/* 에러 메시지 */}
        {error && (
          <div className="mb-4 p-4 bg-red-100 border border-red-400 text-red-700 rounded">
            {error}
          </div>
        )}

        {/* 레시피 목록 */}
        {recipes.length === 0 ? (
          <div className="text-center py-20">
            <div className="text-6xl mb-4">🍳</div>
            <p className="text-xl text-[#616161] mb-4">아직 생성된 레시피가 없습니다.</p>
            <button
              onClick={handleCreateRecipe}
              disabled={creating}
              className="px-8 py-3 bg-[#f21d1d] text-white rounded-lg hover:opacity-90 transition disabled:opacity-50"
            >
              첫 레시피 생성하기
            </button>
          </div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {recipes.map((recipe, index) => (
              <div
                key={index}
                onClick={() => router.push(`/recipes/${index + 1}`)}
                className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition cursor-pointer"
              >
                <div className="flex items-center justify-between mb-4">
                  <span
                    className={`px-3 py-1 rounded-full text-sm font-medium ${
                      recipe.decision === 'COOK'
                        ? 'bg-green-100 text-green-800'
                        : 'bg-orange-100 text-orange-800'
                    }`}
                  >
                    {recipe.decision === 'COOK' ? '🍳 요리 추천' : '🚚 배달 추천'}
                  </span>
                </div>

                <p className="text-[#616161] mb-4">{recipe.reason}</p>

                {recipe.recipes && recipe.recipes.length > 0 && (
                  <div className="border-t pt-4">
                    <p className="font-medium mb-2">추천 레시피:</p>
                    <ul className="space-y-1">
                      {recipe.recipes.map((r, i) => (
                        <li key={i} className="text-sm text-[#616161]">
                          • {r.recipeName}
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
