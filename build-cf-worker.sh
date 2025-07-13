#!/bin/bash

# Build otimizado para Cloudflare Worker com baixo uso de memória
set -e

echo "🚀 Building Cloudflare Worker com otimizações de memória..."

# Configurar ambiente para baixo uso de memória
export CARGO_BUILD_JOBS=1
export RUSTC_FORCE_INCREMENTAL=1
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16

# Build com wasm-pack usando configurações otimizadas
echo "🔧 Compilando WebAssembly..."
(cd crates/server-cf-worker && wasm-pack build --target bundler --out-name exograph_cf_worker -- --jobs 1)

echo "📦 Preparando distribuição..."
mkdir -p target/cf-worker-dist
cp crates/server-cf-worker/pkg/*.wasm target/cf-worker-dist
cp crates/server-cf-worker/pkg/*.js target/cf-worker-dist
cp crates/server-cf-worker/js/exograph_cf_worker.js target/cf-worker-dist
cp crates/server-cf-worker/js/index.js target/cf-worker-dist
cp LICENSE target/cf-worker-dist

echo "🗜️  Criando arquivo ZIP..."
(cd target/cf-worker-dist/ && zip ../exograph-cf-worker-wasm.zip *)

echo "✅ Build do Cloudflare Worker concluído!"
  