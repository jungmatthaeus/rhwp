# 1. WASM 빌드 단계
FROM rust:1.77-slim AS wasm-builder
RUN apt-get update && apt-get install -y curl pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
RUN curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh
WORKDIR /app
COPY . .
RUN wasm-pack build --target web

# 2. 프론트엔드 빌드 단계
FROM node:18-alpine AS frontend-builder
WORKDIR /app
COPY --from=wasm-builder /app /app
WORKDIR /app/rhwp-studio
RUN npm install
RUN npm run build

# 3. 최종 Nginx 배포 단계
FROM nginx:alpine
COPY --from=frontend-builder /app/rhwp-studio/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
