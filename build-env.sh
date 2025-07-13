# Configurações de ambiente para reduzir uso de memória durante builds
# Source este arquivo antes de executar builds: source build-env.sh

# Limita o número de jobs paralelos do cargo
export CARGO_BUILD_JOBS=1

# Configurações do compilador Rust para usar menos memória
export RUSTC_FORCE_INCREMENTAL=1
export CARGO_INCREMENTAL=1

# Configurações de perfil para usar menos memória
export CARGO_PROFILE_DEV_CODEGEN_UNITS=256
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16
export CARGO_PROFILE_DEV_DEBUG=0

# Configurações do linker para usar menos memória
export CARGO_PROFILE_DEV_LTO="off"
export CARGO_PROFILE_RELEASE_LTO="thin"

# Configurações para builds WebAssembly (usado no cf-worker)
export WASM_PACK_CACHE_PATH="./target/wasm-pack-cache"

# Configurações de memória do sistema (se disponível)
if command -v ulimit >/dev/null 2>&1; then
    # Limita memória virtual a 4GB (ajuste conforme necessário)
    ulimit -v 4194304  # 4GB em KB
    echo "✅ Limite de memória virtual definido para 4GB"
fi

# Configurações para sistemas com pouca memória
export CARGO_NET_RETRY=3
export CARGO_HTTP_TIMEOUT=30

echo "🔧 Ambiente configurado para build com baixo uso de memória"
echo "📊 Jobs paralelos: $CARGO_BUILD_JOBS"
echo "🧠 Build incremental: $CARGO_INCREMENTAL"
echo "🔗 LTO: thin (release) / off (dev)"
