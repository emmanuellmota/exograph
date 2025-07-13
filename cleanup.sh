#!/bin/bash
# Script de limpeza para arquivos temporários do build

echo "🧹 Limpando arquivos temporários..."

# Remover pacotes antigos
rm -rf exograph-custom-package
rm -rf exograph-complete-package
rm -f exograph-custom-*.tar.gz

echo "✅ Limpeza concluída!"
echo ""
echo "📦 Arquivos mantidos:"
echo "   - generate-self-installer.sh (gerador)"
echo "   - exograph-self-installer.sh (instalador final)"
ls -lh generate-self-installer.sh exograph-self-installer.sh 2>/dev/null || true
