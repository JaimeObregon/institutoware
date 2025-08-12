#!/usr/bin/env bash
# historify.sh — Importa cada fichero haciendo un commit con su mtime
# Uso:
#   ./historify.sh               # ejecuta
#   ./historify.sh --dry-run     # simula sin commitear
# Opcionales:
#   GIT_AUTHOR_NAME="Tu Nombre" GIT_AUTHOR_EMAIL="tu@correo" ./historify.sh
#   (si no se establecen, se usan los de `git config`)

set -euo pipefail

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

# Verificaciones básicas
if ! command -v git >/dev/null 2>&1; then
  echo "Error: git no está instalado." >&2
  exit 1
fi

if [[ ! -d .git ]]; then
  echo "No hay repo git. Inicializando..."
  git init
fi

# Asegura que hay nombre/email de autor configurados si no se pasan vía env
if [[ -z "${GIT_AUTHOR_NAME:-}" ]]; then
  if ! git config user.name >/dev/null; then
    echo "Configura 'git config user.name' o exporta GIT_AUTHOR_NAME." >&2
    exit 1
  fi
fi
if [[ -z "${GIT_AUTHOR_EMAIL:-}" ]]; then
  if ! git config user.email >/dev/null; then
    echo "Configura 'git config user.email' o exporta GIT_AUTHOR_EMAIL." >&2
    exit 1
  fi
fi

# Recolecta (epoch \t ruta) de todos los ficheros, excluyendo .git
tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

# Nota: -print0 para robustez con espacios; usamos una línea por archivo en el tmp.
# En macOS, epoch con: stat -f "%m"
find . -type f -not -path "./.git/*" -print0 |
while IFS= read -r -d '' f; do
  # Quita el prefijo ./ para mensajes más bonitos (opcional)
  display="${f#./}"
  # Epoch del mtime
  epoch="$(stat -f '%m' "$f")"
  printf '%s\t%s\n' "$epoch" "$display" >> "$tmpfile"
done

# Ordena por fecha (ascendente)
sort -n -k1,1 "$tmpfile" -o "$tmpfile"

total="$(wc -l < "$tmpfile" | tr -d ' ')"
echo "Ficheros a procesar: $total"

i=0
while IFS=$'\t' read -r epoch file; do
  i=$((i+1))
  # Fecha ISO para el mensaje (UTC)
  iso="$(TZ=UTC date -r "$epoch" '+%Y-%m-%d %H:%M:%S UTC')"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[$i/$total] Commitear: $file  @ $iso"
    continue
  fi

  # Asegura que existe (por si cambió entre el scan y ahora)
  if [[ ! -f "$file" ]]; then
    echo "Saltando (no existe): $file" >&2
    continue
  fi

  git add -- "$file"

  GIT_AUTHOR_DATE="@$epoch" \
  GIT_COMMITTER_DATE="@$epoch" \
  git commit -m "Import ${file} (mtime: ${iso})" --quiet

  echo "[$i/$total] Commit: $file  @ $iso"
done < "$tmpfile"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "Dry run completado. Nada se ha commiteado."
else
  echo "Hecho. Último commit:"
  git --no-pager log -1 --stat
fi

