import type { NextConfig } from 'next';

// Next.js 설정
// 이미지 최적화 및 외부 도메인 허용 설정
const nextConfig: NextConfig = {
  // 이미지 최적화: 외부 이미지 도메인 허용
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'recook.kr',
      },
    ],
  },
};

export default nextConfig;
