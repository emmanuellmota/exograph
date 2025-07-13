#!/bin/bash

# Script para build com limitação de memória
# Este script limita o uso de recursos durante o processo de build

set -e

# Configurações de limite de memória
MEMORY_LIMIT="8G"  # Ajuste conforme necessário (ex: 2G, 8G, etc.)
JOBS=1  # Número de jobs paralelos

echo "🚀 Iniciando build com limitação de memória..."
echo "📊 Limite de memória: $MEMORY_LIMIT"
echo "🔧 Jobs paralelos: $JOBS"

# Função para verificar se o comando ulimit está disponível
check_ulimit() {
    if command -v ulimit >/dev/null 2>&1; then
        echo "✅ ulimit disponível"
        return 0
    else
        echo "⚠️  ulimit não disponível, continuando sem limitação de memória virtual"
        return 1
    fi
}

# Função para verificar se o comando systemd-run está disponível
check_systemd() {
    if command -v systemd-run >/dev/null 2>&1; then
        echo "✅ systemd-run disponível"
        return 0
    else
        echo "⚠️  systemd-run não disponível"
        return 1
    fi
}

# Configurar variáveis de ambiente para reduzir uso de memória
export CARGO_BUILD_JOBS=$JOBS
export CARGO_PROFILE_DEV_CODEGEN_UNITS=256
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16
export RUSTC_FORCE_INCREMENTAL=1

# Limpeza antes do build
echo "🧹 Limpando cache anterior..."
cargo clean

# Método 1: Usar systemd-run (recomendado para sistemas com systemd)
if check_systemd; then
    echo "🔄 Usando systemd-run para limitação de memória..."
    systemd-run --user --scope -p MemoryMax=$MEMORY_LIMIT \
        cargo build --jobs $JOBS "$@"
    
# Método 2: Usar ulimit (fallback)
elif check_ulimit; then
    echo "🔄 Usando ulimit para limitação de memória..."
    # Converter limite de memória para KB (ulimit usa KB)
    MEMORY_KB=$(echo $MEMORY_LIMIT | sed 's/G/*1024*1024/g; s/M/*1024/g' | bc)
    
    # Aplicar limites
    ulimit -v $MEMORY_KB  # Memória virtual
    ulimit -m $MEMORY_KB  # Memória residente
    
    cargo build --jobs $JOBS "$@"
    
# Método 3: Build normal com configurações otimizadas
else
    echo "🔄 Build normal com configurações de baixo uso de memória..."
    cargo build --jobs $JOBS "$@"
fi

echo "✅ Build concluído!"
