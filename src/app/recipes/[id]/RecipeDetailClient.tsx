/**
 * 레시피 상세 클라이언트 컴포넌트
 * 실제 레시피 내용을 표시
 */

'use client';

import { useRouter } from 'next/navigation';
import { RecipesResponse } from '@/types/models';

/** Props */
interface RecipeDetailClientProps {
  recipe: RecipesResponse;
}

/**
 * 레시피 상세 클라이언트 컴포넌트
 */
export default function RecipeDetailClient({ recipe }: RecipeDetailClientProps) {
  const router = useRouter();

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
          <div className="space-x-4">
            <button
              onClick={() => router.push('/recipes')}
              className="px-6 py-2 text-[#616161] hover:text-[#f21d1d] transition"
            >
              목록으로
            </button>
            <button
              onClick={() => router.push('/')}
              className="px-6 py-2 text-[#616161] hover:text-[#f21d1d] transition"
            >
              홈으로
            </button>
          </div>
        </div>
      </header>

      {/* 메인 콘텐츠 */}
      <main className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          {/* 결정 타입 */}
          <div className="mb-6">
            <span
              className={`px-4 py-2 rounded-full text-lg font-medium ${
                recipe.decision === 'COOK'
                  ? 'bg-green-100 text-green-800'
                  : 'bg-orange-100 text-orange-800'
              }`}
            >
              {recipe.decision === 'COOK' ? '🍳 요리 추천' : '🚚 배달 추천'}
            </span>
          </div>

          {/* 추천 이유 */}
          <div className="bg-white p-6 rounded-lg shadow-md mb-8">
            <h2 className="text-2xl font-bold mb-4">추천 이유</h2>
            <p className="text-lg text-[#616161]">{recipe.reason}</p>
          </div>

          {/* 레시피 목록 */}
          {recipe.recipes && recipe.recipes.length > 0 ? (
            <div className="space-y-8">
              {recipe.recipes.map((r, index) => (
                <div key={index} className="bg-white p-8 rounded-lg shadow-md">
                  {/* 레시피 이름 */}
                  <h3 className="text-3xl font-bold mb-6">{r.recipeName}</h3>

                  {/* 레시피 이미지 */}
                  {r.imageUrl && (
                    <div className="mb-6">
                      <img
                        src={r.imageUrl}
                        alt={r.recipeName}
                        className="w-full h-64 object-cover rounded-lg"
                      />
                    </div>
                  )}

                  {/* 재료 */}
                  <div className="mb-6">
                    <h4 className="text-xl font-bold mb-3">재료</h4>
                    <ul className="space-y-2">
                      {r.ingredients.map((ingredient, i) => (
                        <li key={i} className="flex items-start">
                          <span className="text-[#f21d1d] mr-2">•</span>
                          <span className="text-[#616161]">{ingredient}</span>
                        </li>
                      ))}
                    </ul>
                  </div>

                  {/* 조리 과정 */}
                  <div>
                    <h4 className="text-xl font-bold mb-3">조리 과정</h4>
                    <ol className="space-y-4">
                      {r.steps.map((step, i) => (
                        <li key={i} className="flex items-start">
                          <span className="flex-shrink-0 w-8 h-8 bg-[#f21d1d] text-white rounded-full flex items-center justify-center mr-3 font-bold">
                            {i + 1}
                          </span>
                          <span className="text-[#616161] pt-1">{step}</span>
                        </li>
                      ))}
                    </ol>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="bg-white p-8 rounded-lg shadow-md text-center">
              <div className="text-6xl mb-4">🚚</div>
              <p className="text-xl text-[#616161]">
                배달을 추천드립니다. 맛있는 음식을 주문해보세요!
              </p>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
