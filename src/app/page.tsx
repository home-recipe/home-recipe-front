/**
 * 홈/랜딩 페이지
 * 풀스크린 이미지 슬라이더 + 미니멀 텍스트 오버레이
 * 군더더기 없는 고해상도 웹사이트 스타일
 */

'use client';

import { useState, useEffect, useCallback } from 'react';

/**
 * 슬라이드 데이터 타입
 */
interface Slide {
  image: string;
  title: string;
  description: string;
}

/**
 * 슬라이드 데이터
 * 각 이미지에 대응하는 텍스트 문구
 */
const slides: Slide[] = [
  {
    image: '/assets/front/1.png',
    title: 'AI가 추천하는 맞춤형 레시피',
    description: '당신의 취향과 상황에 맞는 완벽한 레시피를 찾아드립니다.',
  },
  {
    image: '/assets/front/2.png',
    title: '요리할지, 배달할지 고민될 때',
    description: 'Re:Cook이 최적의 선택을 도와드립니다.',
  },
  {
    image: '/assets/front/3.png',
    title: '나만의 레시피 저장소',
    description: '좋아하는 레시피를 저장하고 언제든 다시 만나보세요.',
  },
];

/**
 * 홈 페이지 컴포넌트
 * 풀스크린 배경 이미지 캐러셀 + 중앙 텍스트만으로 구성된 미니멀 디자인
 */
export default function HomePage() {
  /* 현재 활성화된 슬라이드 인덱스 */
  const [currentSlide, setCurrentSlide] = useState(0);
  /* 페이드 전환 상태 */
  const [isTransitioning, setIsTransitioning] = useState(false);

  /**
   * 다음 슬라이드로 전환하는 함수
   * 페이드 아웃 → 슬라이드 변경 → 페이드 인
   */
  const goToNext = useCallback(() => {
    setIsTransitioning(true);
    setTimeout(() => {
      setCurrentSlide((prev) => (prev + 1) % slides.length);
      setIsTransitioning(false);
    }, 800);
  }, []);

  /**
   * 자동 슬라이드 전환
   * 6초마다 다음 슬라이드로 부드럽게 전환
   */
  useEffect(() => {
    const timer = setInterval(goToNext, 6000);
    return () => clearInterval(timer);
  }, [goToNext]);

  return (
    <div className="relative w-full h-full overflow-hidden">

      {/* ===== 배경 이미지 레이어 ===== */}
      {slides.map((slide, index) => (
        <div
          key={index}
          className={`absolute inset-0 transition-opacity duration-[1500ms] ease-in-out ${
            index === currentSlide && !isTransitioning
              ? 'opacity-100'
              : 'opacity-0'
          }`}
          style={{
            backgroundImage: `url(${slide.image})`,
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            backgroundRepeat: 'no-repeat',
          }}
        >
          {/* 어두운 그라데이션 오버레이 - 텍스트 가독성 */}
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/30 to-black/20" />
        </div>
      ))}

      {/* ===== 중앙 텍스트 오버레이 ===== */}
      <div className="relative z-10 h-full flex items-center justify-center px-6">
        <div className="text-center">
          {/* 메인 타이틀 - 한 줄 고정, 반응형 크기 조절 */}
          <h1
            className={`whitespace-nowrap font-bold text-white
              text-[clamp(1.5rem,5vw,4.5rem)] leading-tight
              transition-all duration-[1200ms] ease-in-out
              ${isTransitioning ? 'opacity-0 translate-y-3' : 'opacity-100 translate-y-0'}`}
            style={{
              textShadow: '0 2px 20px rgba(0,0,0,0.6), 0 0px 8px rgba(0,0,0,0.4)',
            }}
          >
            {slides[currentSlide].title}
          </h1>

          {/* 서브 설명 텍스트 */}
          <p
            className={`mt-4 text-white/80 text-sm md:text-lg font-light tracking-wide
              transition-all duration-[1200ms] ease-in-out delay-100
              ${isTransitioning ? 'opacity-0 translate-y-3' : 'opacity-100 translate-y-0'}`}
            style={{
              textShadow: '0 1px 10px rgba(0,0,0,0.5)',
            }}
          >
            {slides[currentSlide].description}
          </p>
        </div>
      </div>

      {/* ===== 하단 슬라이드 인디케이터 ===== */}
      <div className="absolute bottom-8 left-1/2 -translate-x-1/2 z-20 flex gap-2.5">
        {slides.map((_, index) => (
          <button
            key={index}
            onClick={() => {
              if (index === currentSlide) return;
              setIsTransitioning(true);
              setTimeout(() => {
                setCurrentSlide(index);
                setIsTransitioning(false);
              }, 800);
            }}
            className={`h-2 rounded-full transition-all duration-500
              ${index === currentSlide
                ? 'bg-white w-7'
                : 'bg-white/40 w-2 hover:bg-white/60'}`}
            aria-label={`슬라이드 ${index + 1}로 이동`}
          />
        ))}
      </div>
    </div>
  );
}
