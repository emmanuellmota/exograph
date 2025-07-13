#!/bin/bash

# Script para build incremental por subsistema
# Permite buildar o projeto em etapas menores para evitar estouro de memória

set -e

WORKSPACE_ROOT="/home/emmanuellmota/projects/exograph"

echo "🔧 Build incremental por subsistema - Exograph"
echo "📁 Workspace: $WORKSPACE_ROOT"

# Configurar variáveis para baixo uso de memória
export CARGO_BUILD_JOBS=1
export CARGO_PROFILE_DEV_CODEGEN_UNITS=256
export RUSTC_FORCE_INCREMENTAL=1

cd "$WORKSPACE_ROOT"

# Função para build com retry em caso de falha por memória
build_with_retry() {
    local target="$1"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "🚀 Tentativa $attempt/$max_attempts: Building $target..."
        
        if cargo build -p "$target" --jobs 1; then
            echo "✅ $target built successfully!"
            return 0
        else
            echo "❌ Falha no build de $target (tentativa $attempt)"
            
            if [ $attempt -lt $max_attempts ]; then
                echo "🧹 Limpando cache e tentando novamente..."
                cargo clean -p "$target"
                sleep 5
            fi
            
            ((attempt++))
        fi
    done
    
    echo "💥 Falha definitiva no build de $target após $max_attempts tentativas"
    return 1
}

# Lista de subsistemas em ordem de dependência (do mais básico para o mais complexo)
SUBSYSTEMS=(
    "exo-env"
    "exo-sql"
    "exo-deno"
    "exo-wasm"
    "common"
    "subsystem-util"
    "introspection-util"
    "core-subsystem"
    "postgres-subsystem"
    "deno-subsystem"
    "wasm-subsystem"
    "introspection-subsystem"
    "server-common"
    "system-router"
    "graphql-router"
    "rest-router"
    "rpc-router"
    "mcp-router"
    "mcp-bridge"
    "playground-router"
    "server-actix"
    "testing"
    "builder"
    "cli"
    "lsp"
)

echo "📋 Subsistemas a serem compilados: ${#SUBSYSTEMS[@]}"

# Build incremental
for subsystem in "${SUBSYSTEMS[@]}"; do
    echo ""
    echo "🔄 Processando: $subsystem"
    
    # Verifica se o subsistema existe
    if cargo metadata --format-version 1 | grep -q "\"name\":\"$subsystem\""; then
        build_with_retry "$subsystem"
    else
        echo "⚠️  Subsistema $subsystem não encontrado, pulando..."
    fi
    
    echo "💾 Liberando memória cache..."
    sync
    echo 1 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true
done

echo ""
echo "🎉 Build incremental concluído!"
echo "💡 Para build completo, execute: cargo build --workspace"
