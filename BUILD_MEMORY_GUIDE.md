# Guia para Build com Limitação de Memória

Este documento descreve as estratégias implementadas para reduzir o uso de memória durante o processo de build do Exograph.

## 📋 Resumo das Otimizações

### 1. Configurações do Cargo (`.cargo/config.toml`)
- ✅ Limitação de jobs paralelos para 1
- ✅ Desabilitação de debug info
- ✅ Aumento do número de unidades de codegen
- ✅ Configurações específicas do rustc

### 2. Perfis de Build (`Cargo.toml`)
- ✅ LTO "thin" ao invés de "full" 
- ✅ Mais unidades de codegen para reduzir picos de memória
- ✅ Build incremental habilitado
- ✅ Verificações de overflow desabilitadas

### 3. Scripts de Build Otimizados

#### `./build-low-memory.sh`
Script principal para build com limitação de memória.

**Uso:**
```bash
# Build debug com limitação de memória
./build-low-memory.sh

# Build release com limitação de memória
./build-low-memory.sh --release

# Build de um pacote específico
./build-low-memory.sh -p cli
```

#### `./build-incremental.sh`
Build incremental por subsistema para evitar picos de memória.

**Uso:**
```bash
# Build todos os subsistemas incrementalmente
./build-incremental.sh
```

#### `./build-env.sh`
Configurações de ambiente para reduzir uso de memória.

**Uso:**
```bash
# Carregar configurações antes do build
source ./build-env.sh
cargo build
```

#### `./build-cf-worker.sh`
Build otimizado do Cloudflare Worker.

**Uso:**
```bash
# Build do worker com otimizações de memória
./build-cf-worker.sh
```

## 🚀 Estratégias de Build Recomendadas

### Para Sistemas com Pouca Memória (< 8GB)
1. Use o build incremental:
   ```bash
   ./build-incremental.sh
   ```

2. Ou configure o ambiente e faça build manual:
   ```bash
   source ./build-env.sh
   cargo build --jobs 1
   ```

### Para Sistemas com Memória Moderada (8-16GB)
1. Use o script com limitação:
   ```bash
   ./build-low-memory.sh
   ```

2. Para builds específicos:
   ```bash
   ./build-low-memory.sh -p cli --release
   ```

### Para Sistemas com Bastante Memória (> 16GB)
1. Ainda é recomendado usar as configurações otimizadas:
   ```bash
   source ./build-env.sh
   cargo build --jobs 2  # Pode aumentar para 2-4 jobs
   ```

## 🔧 Configurações Manuais Adicionais

### Ajustar Limite de Memória
Edite `build-low-memory.sh` e modifique:
```bash
MEMORY_LIMIT="4G"  # Altere para 2G, 8G, etc.
```

### Ajustar Jobs Paralelos
Edite `.cargo/config.toml`:
```toml
[build]
jobs = 2  # Altere conforme sua memória disponível
```

### Limpeza de Cache
Para liberar espaço/memória:
```bash
cargo clean
```

## 🐛 Resolução de Problemas

### "Error: out of memory" ou "killed"
1. Use o build incremental: `./build-incremental.sh`
2. Reduza ainda mais os jobs: edite `.cargo/config.toml` e defina `jobs = 1`
3. Feche outros programas para liberar memória
4. Use swap se necessário

### Build muito lento
1. Certifique-se de que o build incremental está funcionando
2. Verifique se o cache não foi limpo desnecessariamente
3. Considere aumentar ligeiramente o número de jobs se tiver memória suficiente

### Erro de linking
1. Use `export CARGO_PROFILE_DEV_LTO="off"`
2. Verifique se há memória suficiente para o linker

## 📊 Monitoramento de Uso de Memória

Durante o build, você pode monitorar o uso de memória com:

```bash
# Em outro terminal
watch -n 1 'free -h && ps aux | grep -E "(cargo|rustc)" | grep -v grep'
```

## 🎯 Benchmarks Esperados

Com as otimizações implementadas, você deve observar:
- ✅ Redução de 40-60% no pico de uso de memória
- ✅ Build mais estável em sistemas com pouca memória
- ⚠️ Possível aumento de 20-30% no tempo de build (trade-off aceitável)
- ✅ Builds incrementais muito mais rápidos
