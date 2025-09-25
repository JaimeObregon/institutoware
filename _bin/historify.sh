#!/usr/bin/env bash
#
# === Script escrito por una IA ===
#
# historify.sh — Importa los ficheros indicados haciendo un commit por fichero con su mtime.
# Uso:
#   ./historify.sh ruta1 [ruta2 ...]          # procesa solo esas rutas (fichero o directorio)
#   ./historify.sh --dry-run ruta1 [ruta2 ...]
# Opcionales:
#   GIT_AUTHOR_NAME="Tu Nombre" GIT_AUTHOR_EMAIL="tu@correo" ./historify.sh ...
#   (si no se establecen, se usan los de `git config`)
#
# Notas:
# - Directorios se recorren recursivamente (excluye .git).
# - Orden: de más antiguo a más reciente por mtime, para reconstruir historia.
# - Solo añade/commitea los ficheros indicados; no toca el resto del repo.
# - Compatible con macOS (BSD) y Linux (GNU coreutils).
#
set -euo pipefail

show_help() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

DRY_RUN=0
ARGS=()

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      show_help
      exit 0
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    -*)
      echo "Opción no reconocida: $arg" >&2
      exit 2
      ;;
    *)
      ARGS+=("$arg")
      ;;
  esac
done

if [[ ${#ARGS[@]} -eq 0 ]]; then
  echo "Error: especifica al menos una ruta (fichero o directorio)." >&2
  echo "Ejemplo: $0 --dry-run /ruta/al/fichero /ruta/al/directorio" >&2
  exit 2
fi

# Comprobaciones Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Este directorio no es un repo Git. Inicializa con: git init" >&2
  exit 2
fi

# Comprobar nombre/email
if ! git config user.name >/dev/null; then
  if [[ -z "${GIT_AUTHOR_NAME:-}" ]]; then
    echo "Configura 'git config user.name' o exporta GIT_AUTHOR_NAME." >&2
    exit 2
  fi
fi
if ! git config user.email >/dev/null; then
  if [[ -z "${GIT_AUTHOR_EMAIL:-}" ]]; then
    echo "Configura 'git config user.email' o exporta GIT_AUTHOR_EMAIL." >&2
    exit 2
  fi
fi

# Funciones portables para epoch (mtime) e ISO8601
epoch_mtime() {
  # $1 = ruta
  if stat -f %m "$1" >/dev/null 2>&1; then
    stat -f %m "$1"         # macOS/BSD
  elif stat -c %Y "$1" >/dev/null 2>&1; then
    stat -c %Y "$1"         # GNU
  else
    # Último recurso: Perl
    perl -e 'print((stat(shift))[9])' "$1"
  fi
}

iso_from_epoch() {
  # $1 = epoch (segundos)
  if date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
    date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ   # macOS/BSD
  else
    date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ  # GNU
  fi
}

# Construir lista de ficheros a procesar
files=()
while IFS= read -r -d '' p; do
  files+=("$p")
done < <(
  for R in "${ARGS[@]}"; do
    if [[ -d "$R" ]]; then
      # Excluir .git y solo ficheros regulares
      find "$R" -type d -name .git -prune -o -type f -print0
    elif [[ -f "$R" ]]; then
      printf '%s\0' "$R"
    else
      echo "Aviso: se ignora (no existe): $R" >&2
    fi
  done
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No hay ficheros que procesar." >&2
  exit 0
fi

# Ordenar por mtime ascendente (portablemente)
# Generamos "epoch<TAB>ruta", ordenamos por epoch, y extraemos ruta.
sorted_files=()
while IFS= read -r line; do
  # shellcheck disable=SC2206
  arr=($line)
  # Re-unir por si hubiera espacios en la ruta (ya protegidos con printf %q más abajo si hace falta)
  epoch="${arr[0]}"
  path="${line#*$epoch	}"
  sorted_files+=("$path")
done < <(
  # printf de pares epoch<tab>ruta (ruta en formato intacto)
  for f in "${files[@]}"; do
    e="$(epoch_mtime "$f")"
    printf '%s\t%s\n' "$e" "$f"
  done | sort -n -k1,1
)

total=${#sorted_files[@]}
i=0

# Confirmación si hay algo staged previamente (evitar mezclar commits)
if [[ -n "$(git diff --name-only --cached)" ]]; then
  echo "Hay cambios ya 'staged' en el índice. Salgo para no mezclarlos." >&2
  echo "Sugerencia: 'git reset' para vaciar el índice y vuelve a ejecutar." >&2
  exit 2
fi

for file in "${sorted_files[@]}"; do
  ((i++)) || true

  if [[ ! -f "$file" ]]; then
    echo "[$i/$total] Saltando (no es fichero regular): $file" >&2
    continue
  fi

  epoch="$(epoch_mtime "$file")"
  iso="$(iso_from_epoch "$epoch")"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[$i/$total] Commit -> $file  @ $iso"
    continue
  fi

  # Añadir solo ese fichero al índice
  git add -- "$file"

  # Hacer commit usando el mtime como fecha de autor y committer
  GIT_AUTHOR_DATE="@$epoch" \
  GIT_COMMITTER_DATE="@$epoch" \
  git commit -m "Import ${file} (mtime: ${iso})" --quiet

  echo "[$i/$total] Commit: $file  @ $iso"
done

if [[ $DRY_RUN -eq 1 ]]; then
  echo "Dry run completado. Nada se ha commiteado."
else
  echo "Hecho. Último commit:"
  git --no-pager log -1 --stat
fi
