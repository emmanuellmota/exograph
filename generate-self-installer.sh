#!/bin/bash
# Gerador de Self-Installer para Exograph
# Este script cria um instalador auto-extraível com os binários embarcados

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Gerador de Self-Installer Exograph ===${NC}"
echo ""

# Verificar se estamos no diretório correto
if [ ! -f "Cargo.toml" ] || [ ! -d "target/release" ]; then
    echo -e "${RED}❌ Erro: Execute este script no diretório raiz do projeto Exograph${NC}"
    echo -e "${RED}   Certifique-se de que 'cargo build --release' foi executado${NC}"
    exit 1
fi

# Verificar binários
REQUIRED_BINARIES=("target/release/exo" "target/release/exo-server")
OPTIONAL_BINARIES=("target/release/exo-lsp" "target/release/exo-mcp-bridge")
MISSING_REQUIRED=false

echo -e "${YELLOW}Verificando binários...${NC}"
for binary in "${REQUIRED_BINARIES[@]}"; do
    if [ ! -f "$binary" ]; then
        echo -e "${RED}❌ $binary não encontrado${NC}"
        MISSING_REQUIRED=true
    else
        echo -e "${GREEN}✓ $binary encontrado${NC}"
    fi
done

if [ "$MISSING_REQUIRED" = true ]; then
    echo -e "${RED}Execute 'cargo build --release' primeiro${NC}"
    exit 1
fi

for binary in "${OPTIONAL_BINARIES[@]}"; do
    if [ -f "$binary" ]; then
        echo -e "${GREEN}✓ $binary encontrado (opcional)${NC}"
    else
        echo -e "${YELLOW}⚠ $binary não encontrado (opcional)${NC}"
    fi
done

# Obter informações da build
BUILD_DATE=$(date -Iseconds)
ARCH=$(uname -m)
SYSTEM=$(uname -a)
RUST_VERSION=$(rustc --version 2>/dev/null || echo "N/A")
GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "N/A")

# Nome do arquivo final
OUTPUT_FILE="exograph-self-installer.sh"

echo ""
echo -e "${BLUE}Gerando self-installer: $OUTPUT_FILE${NC}"

# Criar diretório temporário para o payload
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copiar binários para diretório temporário
mkdir -p "$TEMP_DIR/bin"
for binary in "${REQUIRED_BINARIES[@]}" "${OPTIONAL_BINARIES[@]}"; do
    if [ -f "$binary" ]; then
        cp "$binary" "$TEMP_DIR/bin/"
        chmod +x "$TEMP_DIR/bin/$(basename "$binary")"
    fi
done

# Criar arquivo de informações da build no payload
cat > "$TEMP_DIR/BUILD_INFO.txt" << EOF
Exograph Self-Installer Build Information
========================================
Build Date: $BUILD_DATE
Architecture: $ARCH
System: $SYSTEM
Rust Version: $RUST_VERSION
Git Hash: $GIT_HASH
EOF

# Criar arquivo tar.gz do payload
cd "$TEMP_DIR"
tar -czf "../payload.tar.gz" .
cd - >/dev/null
PAYLOAD_SIZE=$(stat -c%s "$TEMP_DIR/../payload.tar.gz")

echo -e "${GREEN}✓ Payload criado (${PAYLOAD_SIZE} bytes)${NC}"

# Gerar o self-installer
cat > "$OUTPUT_FILE" << 'INSTALLER_HEADER'
#!/bin/bash
# Exograph Self-Installer
# Este arquivo contém os binários embarcados e se auto-extrai

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurações
INSTALL_DIR="${EXOGRAPH_INSTALL:-$HOME/.exograph}"
BIN_DIR="$INSTALL_DIR/bin"

# Função para extrair payload
extract_payload() {
    local archive_line=$(awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' "$0")
    tail -n+$archive_line "$0" | tar -xzf - -C "$1"
}

# Banner
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║               EXOGRAPH SELF-INSTALLER                   ║${NC}"
echo -e "${BLUE}║                  ARM64 (aarch64)                        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar compatibilidade
echo -e "${YELLOW}🔍 Verificando compatibilidade do sistema...${NC}"
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo -e "${RED}❌ Sistema incompatível!${NC}"
    echo -e "${RED}   Detectado: $ARCH${NC}"
    echo -e "${RED}   Necessário: aarch64${NC}"
    echo -e "${RED}   Este instalador foi compilado para ARM64.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Sistema compatível ($ARCH)${NC}"

# Mostrar informações da build
echo ""
echo -e "${BLUE}📋 Informações da Build:${NC}"
TEMP_EXTRACT=$(mktemp -d)
trap "rm -rf $TEMP_EXTRACT" EXIT
extract_payload "$TEMP_EXTRACT"

if [ -f "$TEMP_EXTRACT/BUILD_INFO.txt" ]; then
    while IFS= read -r line; do
        if [[ $line == *":"* ]]; then
            echo -e "${YELLOW}   $line${NC}"
        fi
    done < "$TEMP_EXTRACT/BUILD_INFO.txt"
fi

# Verificar binários incluídos
echo ""
echo -e "${BLUE}📦 Binários incluídos:${NC}"
if [ -d "$TEMP_EXTRACT/bin" ]; then
    for binary in "$TEMP_EXTRACT/bin"/*; do
        if [ -f "$binary" ]; then
            name=$(basename "$binary")
            size=$(ls -lh "$binary" | awk '{print $5}')
            echo -e "${GREEN}   ✓ $name ($size)${NC}"
        fi
    done
fi

# Confirmar instalação
echo ""
read -p "🚀 Deseja instalar o Exograph? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}Instalação cancelada${NC}"
    exit 0
fi

# Criar diretório de instalação
echo -e "${YELLOW}📁 Criando diretório de instalação...${NC}"
if [ ! -d "$BIN_DIR" ]; then
    mkdir -p "$BIN_DIR"
    echo -e "${GREEN}✅ Diretório criado: $BIN_DIR${NC}"
else
    echo -e "${YELLOW}⚠️  Diretório já existe: $BIN_DIR${NC}"
fi

# Instalar binários
echo -e "${YELLOW}⚙️  Instalando binários...${NC}"
INSTALLED_COUNT=0
for binary in "$TEMP_EXTRACT/bin"/*; do
    if [ -f "$binary" ]; then
        name=$(basename "$binary")
        echo -n "   Instalando $name... "
        cp "$binary" "$BIN_DIR/"
        chmod +x "$BIN_DIR/$name"
        echo -e "${GREEN}✅${NC}"
        ((INSTALLED_COUNT++))
    fi
done

echo -e "${GREEN}✅ $INSTALLED_COUNT executáveis instalados${NC}"

# Verificar PATH
echo ""
echo -e "${YELLOW}🔧 Verificando configuração do PATH...${NC}"
if command -v exo >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 'exo' já está disponível no PATH${NC}"
    EXO_VERSION=$(exo --version 2>/dev/null || echo "versão não detectada")
    echo -e "${GREEN}   Versão: $EXO_VERSION${NC}"
else
    echo -e "${YELLOW}⚠️  PATH precisa ser configurado${NC}"
    case $SHELL in
    /bin/zsh) shell_profile=".zshrc" ;;
    *) shell_profile=".bashrc" ;;
    esac
    
    echo -e "${BLUE}💡 Para configurar permanentemente:${NC}"
    echo -e "${BLUE}   echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/$shell_profile${NC}"
    echo -e "${BLUE}   source ~/$shell_profile${NC}"
    echo ""
    echo -e "${BLUE}💡 Para usar imediatamente:${NC}"
    echo -e "${BLUE}   export PATH=\"$BIN_DIR:\$PATH\"${NC}"
    
    read -p "🔧 Configurar PATH automaticamente no $shell_profile? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/$shell_profile"
        echo -e "${GREEN}✅ PATH adicionado ao $shell_profile${NC}"
        echo -e "${YELLOW}⚠️  Execute 'source ~/$shell_profile' ou abra um novo terminal${NC}"
    fi
fi

# Teste final
echo ""
echo -e "${BLUE}🧪 Teste rápido:${NC}"
export PATH="$BIN_DIR:$PATH"
if command -v exo >/dev/null 2>&1; then
    if exo --version >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Exograph está funcionando corretamente!${NC}"
        echo -e "${GREEN}   $(exo --version)${NC}"
    else
        echo -e "${YELLOW}⚠️  Exograph instalado, mas pode precisar de configuração adicional${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Configure o PATH para usar o Exograph${NC}"
fi

# Informações finais
echo ""
echo -e "${GREEN}🎉 Instalação concluída com sucesso!${NC}"
echo ""
echo -e "${BLUE}📚 Próximos passos:${NC}"
echo -e "${BLUE}   1. Configure o PATH (se não foi feito automaticamente)${NC}"
echo -e "${BLUE}   2. Execute: exo --help${NC}"
echo -e "${BLUE}   3. Crie um projeto: exo new meu-projeto${NC}"
echo -e "${BLUE}   4. Visite: https://exograph.dev/docs${NC}"
echo ""
echo -e "${YELLOW}💡 Dica: Use 'exo yolo' para desenvolvimento rápido${NC}"

exit 0

__ARCHIVE_BELOW__
INSTALLER_HEADER

# Anexar o payload ao final do script
cat "$TEMP_DIR/../payload.tar.gz" >> "$OUTPUT_FILE"

# Tornar executável
chmod +x "$OUTPUT_FILE"

# Obter tamanho final
FINAL_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')

echo ""
echo -e "${GREEN}🎉 Self-installer criado com sucesso!${NC}"
echo -e "${GREEN}   Arquivo: $OUTPUT_FILE${NC}"
echo -e "${GREEN}   Tamanho: $FINAL_SIZE${NC}"
echo ""
echo -e "${BLUE}📋 Uso:${NC}"
echo -e "${BLUE}   1. Transferir: scp $OUTPUT_FILE user@servidor:/tmp/${NC}"
echo -e "${BLUE}   2. Executar: chmod +x $OUTPUT_FILE && ./$OUTPUT_FILE${NC}"
echo ""
echo -e "${YELLOW}💡 O arquivo é totalmente portátil e não precisa de arquivos externos${NC}"
