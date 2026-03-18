/**
 * 레시피 상세 페이지 (SSR + SEO)
 * Server Component로 구현하여 SEO 최적화
 * Open Graph 및 JSON-LD 구조화된 데이터 포함
 */

import { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { fetchRecipeById } from '@/lib/api/recipe';
import RecipeDetailClient from './RecipeDetailClient';

/** 페이지 Props */
interface PageProps {
  params: Promise<{
    id: string;
  }>;
}

/**
 * 동적 메타데이터 생성
 * @param props - 페이지 Props
 * @returns 메타데이터
 */
export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { id } = await params;
  const recipe = await fetchRecipeById(id);

  if (!recipe) {
    return {
      title: '레시피를 찾을 수 없습니다 - REC::OOK',
    };
  }

  const title = recipe.recipes && recipe.recipes.length > 0
    ? `${recipe.recipes[0].recipeName} - REC::OOK`
    : 'REC::OOK 레시피';

  const description = recipe.reason || 'AI가 추천하는 맞춤형 레시피';

  const imageUrl = recipe.recipes && recipe.recipes.length > 0 && recipe.recipes[0].imageUrl
    ? recipe.recipes[0].imageUrl
    : 'https://recook.kr/default-recipe-image.jpg';

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      images: [imageUrl],
      type: 'article',
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
      images: [imageUrl],
    },
  };
}

/**
 * 레시피 상세 페이지 (Server Component)
 * @param props - 페이지 Props
 */
export default async function RecipeDetailPage({ params }: PageProps) {
  const { id } = await params;
  const recipe = await fetchRecipeById(id);

  if (!recipe) {
    notFound();
  }

  // JSON-LD 구조화된 데이터 (Recipe Schema)
  const jsonLd = recipe.recipes && recipe.recipes.length > 0 ? {
    '@context': 'https://schema.org',
    '@type': 'Recipe',
    name: recipe.recipes[0].recipeName,
    description: recipe.reason,
    recipeIngredient: recipe.recipes[0].ingredients,
    recipeInstructions: recipe.recipes[0].steps.map((step, index) => ({
      '@type': 'HowToStep',
      position: index + 1,
      text: step,
    })),
    image: recipe.recipes[0].imageUrl || 'https://recook.kr/default-recipe-image.jpg',
  } : null;

  return (
    <>
      {/* JSON-LD 구조화된 데이터 */}
      {jsonLd && (
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      )}

      {/* Client Component로 렌더링 */}
      <RecipeDetailClient recipe={recipe} />
    </>
  );
}
