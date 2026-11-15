#!/bin/sh
# Xcode 26 can sandbox Flutter's impellerc so it cannot write into App.framework.
# Compile into TMPDIR, then copy the outputs to the requested paths.
set -e
REAL="$(cd "$(dirname "$0")" && pwd)/impellerc.real"
if [ ! -x "$REAL" ]; then
  echo "impellerc.real is missing" >&2
  exit 1
fi

tmp="$(mktemp -d "${TMPDIR:-/tmp}/impellerc.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

sl_dest=""
spirv_dest=""
newargs=""
for arg in "$@"; do
  case "$arg" in
    --sl=*)
      sl_dest="${arg#--sl=}"
      arg="--sl=$tmp/out.sl"
      ;;
    --spirv=*)
      spirv_dest="${arg#--spirv=}"
      arg="--spirv=$tmp/out.spirv"
      ;;
  esac
  newargs="$newargs $arg"
done

# shellcheck disable=SC2086
"$REAL" $newargs
status=$?
if [ "$status" -ne 0 ]; then
  exit "$status"
fi

if [ -n "$sl_dest" ]; then
  mkdir -p "$(dirname "$sl_dest")"
  cp "$tmp/out.sl" "$sl_dest"
fi
if [ -n "$spirv_dest" ] && [ -f "$tmp/out.spirv" ]; then
  mkdir -p "$(dirname "$spirv_dest")"
  cp "$tmp/out.spirv" "$spirv_dest"
fi
exit 0
