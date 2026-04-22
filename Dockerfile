# 1단계: Rust를 사용하여 WASM 코어 빌드
FROM rust:1.77-slim AS wasm-builder

# 빌드 필수 도구 설치
RUN apt-get update && apt-get install -y \
    curl \
    pkg-config \
    libssl-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# wasm-pack 설치
RUN curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh

WORKDIR /app
COPY . .

# WASM 패키지 빌드 (결과물은 /app/pkg에 생성됨)
RUN wasm-pack build --target web

# 2단계: Node.js를 사용하여 프론트엔드(Studio) 빌드
FROM node:18-alpine AS frontend-builder

WORKDIR /app
# 1단계의 결과물(pkg 포함)을 복사
COPY --from=wasm-builder /app /app

WORKDIR /app/rhwp-studio
# 의존성 설치 및 정적 파일 빌드
RUN npm install
RUN npm run build

# 3단계: Nginx를 사용하여 최종 웹 서비스 배포
FROM nginx:alpine

# Nginx 기본 설정 및 빌드된 파일 복사
COPY --from=frontend-builder /app/rhwp-studio/dist /usr/share/nginx/html

# 컨테이너 포트 개방
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
