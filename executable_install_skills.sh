#!/usr/bin/env bash
#
# Copy Agent Skills from the shared google3 source tree into ./skills/.
# The source tree is read-only, so plain `cp -r` would preserve those
# permissions and leave the local copy uneditable. This script resets
# permissions to writable and skips google3-only metadata (BUILD, OWNERS).

set -euo pipefail

SOURCE_ROOT="/google/src/files/head/depot/google3/learning/gemini/agents/skills"
DEST_ROOT="${HOME}/.agents/skills"

usage() {
  cat <<EOF
Usage: $(basename "$0") [-f] [-l] [-p] <skill> [<skill> ...]

Copy one or more skills from ${SOURCE_ROOT} into ${DEST_ROOT}/.

Options:
  -f, --force     Overwrite an existing skill directory.
  -l, --list      List skills available at the source and exit.
  -p, --preview   Print SKILL.md for each given skill and exit (no install).
  -h, --help      Show this help.
EOF
}

list_skills() {
  if [[ ! -d "${SOURCE_ROOT}" ]]; then
    echo "error: source not accessible: ${SOURCE_ROOT}" >&2
    exit 1
  fi
  find "${SOURCE_ROOT}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

preview_skill() {
  local name="$1"
  local src="${SOURCE_ROOT}/${name}"

  if [[ ! -d "${src}" ]]; then
    echo "error: skill not found at source: ${name}" >&2
    return 1
  fi

  local skill_md="${src}/SKILL.md"
  if [[ ! -f "${skill_md}" ]]; then
    echo "warning: ${name}/SKILL.md not found, listing directory instead:" >&2
    ls -la "${src}"
    return 0
  fi

  printf '===== %s/SKILL.md =====\n' "${name}"
  cat "${skill_md}"
  printf '\n'
}

install_skill() {
  local name="$1" force="$2"
  local src="${SOURCE_ROOT}/${name}"
  # Agent Skills Spec uses `-`, but google3 source dirs use `_`.
  local dst_name="${name//_/-}"
  local dst="${DEST_ROOT}/${dst_name}"

  if [[ ! -d "${src}" ]]; then
    echo "error: skill not found at source: ${name}" >&2
    return 1
  fi

  if [[ -e "${dst}" ]]; then
    if [[ "${force}" != "1" ]]; then
      echo "skip: ${dst_name} (already exists, pass -f to overwrite)"
      return 0
    fi
    rm -rf "${dst}"
  fi

  mkdir -p "${DEST_ROOT}"
  rsync -a \
    --chmod=u+w \
    --exclude=BUILD \
    --exclude=OWNERS \
    --exclude=METADATA \
    "${src}/" "${dst}/"

  if [[ "${name}" != "${dst_name}" ]]; then
    echo "installed: ${name} -> ${dst_name}"
  else
    echo "installed: ${name}"
  fi
}

force=0
preview=0
skills=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--force)   force=1; shift ;;
    -l|--list)    list_skills; exit 0 ;;
    -p|--preview) preview=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    --)           shift; skills+=("$@"); break ;;
    -*)           echo "error: unknown option: $1" >&2; usage; exit 1 ;;
    *)            skills+=("$1"); shift ;;
  esac
done

if [[ ${#skills[@]} -eq 0 ]]; then
  usage
  exit 1
fi

if [[ "${preview}" == "1" ]]; then
  if [[ ! -d "${SOURCE_ROOT}" ]]; then
    echo "error: source not accessible: ${SOURCE_ROOT}" >&2
    exit 1
  fi
  # Pipe through a pager when stdout is a TTY so long SKILL.md files are readable.
  if [[ -t 1 ]] && command -v less >/dev/null 2>&1; then
    for skill in "${skills[@]}"; do
      preview_skill "${skill}"
    done | less -R
  else
    for skill in "${skills[@]}"; do
      preview_skill "${skill}"
    done
  fi
  exit 0
fi

for skill in "${skills[@]}"; do
  install_skill "${skill}" "${force}"
done
