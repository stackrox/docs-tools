#!/usr/bin/env bash

# Patch the OpenShift docs to be in the format expected by Antora.
#
# Prerequisites:
#  0. DOCS_PATH points to a working copy of the RHACS docs (does not have to be a git directory).
#  1. PATCHED_DOCS_PATH points to the path into which the patched docs will be written. This directory
#     should be empty. If it does not exist, it will be created automatically.

set -e

info() {
  echo >&2 "$@"
}

die() {
  echo >&2 "$@"
  exit 1
}

[[ -n "$DOCS_PATH" ]] || die "DOCS_PATH is empty"
mkdir -p "$PATCHED_DOCS_PATH" || die "Output directory $PATCHED_DOCS_PATH could not be created"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

docs_copy_tmp="$(mktemp -d)"
cp -a "${DOCS_PATH}"/* "$docs_copy_tmp/"
find "${docs_copy_tmp}" -type l -delete


cd "$PATCHED_DOCS_PATH" || die "Could not change directory"

while IFS='' read -r dir || [[ -n "$dir" ]]; do
  name="$(basename "$dir")"
  if [[ "$name" =~ ^[._] ]]; then
    continue
  fi
  target_dir=""
  case "$name" in
  scripts)
    ;;
  modules)
    target_dir=./docs/modules/ROOT/partials/
    ;;
  images)
    target_dir=./docs/modules/ROOT/images/
    ;;
  files)
    target_dir=./docs/modules/ROOT/_files/
    ;;
  welcome)
    target_dir=./docs/modules/ROOT/pages/
    ;;
  *)
    target_dir="./docs/modules/${name}/pages/"
    ;;
  esac
  [[ -n "$target_dir" ]] || continue
  info "Copying $dir/* to $target_dir ..."
  mkdir -p "$target_dir"
  cp -rf "$dir"/* "$target_dir"
done < <(find "$docs_copy_tmp" -depth 1 -type d)

rm -rf "$docs_copy_tmp"

patch_file() {
  local file="$1"
  sed <"$file" 's@include::modules/@include::ROOT:partial$@g' |
    sed -E 's@xref:../([^/]+)/@xref:\1:@g' |
    sed 's@image::@image::ROOT:@g' >"${file}.patched"
  mv "${file}.patched" "$file"
}

while IFS='' read -r file || [[ -n "$file" ]]; do
  info "Patching $file ..."
  patch_file "$file"
done < <(find . -name '*.adoc')

python3 -m venv "${SCRIPT_DIR}/.venv"
. "${SCRIPT_DIR}/.venv/bin/activate"
pip3 install --upgrade pip setuptools
pip3 install -r "${SCRIPT_DIR}/requirements.txt"

"${SCRIPT_DIR}/generate-nav.py" <"${DOCS_PATH}/_topic_map.yml"

git init
git checkout -b "main"
git checkout -b "main"
git add -A .
git commit --author "Docs Builder <rhacs-eng+docsbot@redhat.com>" -am "Initial import"

info "Wrote docs to $PATCHED_DOCS_PATH"
