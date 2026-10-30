#!/bin/bash
# limpar.sh — rode na raiz do repositório:  bash limpar.sh
# 1) apaga cada PNG que já tem um .webp com o mesmo nome ao lado (PNG sem .webp NUNCA é apagado)
# 2) apaga arquivos .DS_Store (lixo do Mac) e cria/atualiza o .gitignore para eles não voltarem
# Antes de apagar, mostra o que vai acontecer e pede confirmação.

lista_png=$(mktemp); lista_ds=$(mktemp); sem_webp=$(mktemp)
trap 'rm -f "$lista_png" "$lista_ds" "$sem_webp"' EXIT

find . -path ./.git -prune -o -type f -iname '*.png' -print | while IFS= read -r f; do
  if [ -f "${f%.*}.webp" ]; then echo "$f" >> "$lista_png"; else echo "$f" >> "$sem_webp"; fi
done
find . -path ./.git -prune -o -type f \( -name '.DS_Store' -o -name 'Thumbs.db' \) -print > "$lista_ds"

n_png=$(wc -l < "$lista_png" | tr -d ' '); n_ds=$(wc -l < "$lista_ds" | tr -d ' '); n_sem=$(wc -l < "$sem_webp" | tr -d ' ')
bytes=0
while IFS= read -r f; do s=$(wc -c < "$f"); bytes=$((bytes + s)); done < "$lista_png"
echo "PNGs com .webp ao lado (serão apagados): $n_png  (~$((bytes / 1048576)) MB)"
echo "PNGs SEM .webp (serão mantidos):          $n_sem"
echo "Arquivos .DS_Store/Thumbs.db:             $n_ds"
if [ "$n_sem" -gt 0 ]; then echo "--- mantidos (sem .webp), primeiros 10:"; head -10 "$sem_webp"; fi

if [ "$n_png" -eq 0 ] && [ "$n_ds" -eq 0 ]; then echo "Nada para limpar."; exit 0; fi
printf "Apagar agora? (s/N) "; read -r r
case "$r" in s|S|sim|SIM)
  while IFS= read -r f; do rm -f "$f"; done < "$lista_png"
  while IFS= read -r f; do rm -f "$f"; done < "$lista_ds"
  touch .gitignore
  for l in ".DS_Store" "Thumbs.db"; do grep -qxF "$l" .gitignore || echo "$l" >> .gitignore; done
  echo "Pronto. Confira o site e depois faça o commit."
  ;;
  *) echo "Nada foi apagado." ;;
esac
