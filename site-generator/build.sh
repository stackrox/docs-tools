#!/usr/bin/env bash


die() {
	echo >&2 "$@"
	exit 1
}

NODE_PATH="$(pwd)/node_modules"

[[ -f package.json && -f yarn.lock && -d "$NODE_PATH" ]] || die "This must be run from within the project directory"

[[ -n "$BUNDLE_PATH" ]] || die "No bundle path specified"
[[ -n "$CONTENT_REPO" ]] || die "No content repo specified"

playbook_yml="$(mktemp)"
cat >"$playbook_yml" <<EOF
site:
  title: RHACS documentation
  start_page: rhacs::index.adoc
content:
  sources:
  - url: $CONTENT_REPO
    branches: main
    start_path: docs
ui:
  bundle:
    url: $BUNDLE_PATH
EOF

export PATH="$(yarn bin):$PATH"

DOCSEARCH_ENABLED=true DOCSEARCH_ENGINE=lunr NODE_PATH="$NODE_PATH" antora --generator antora-site-generator-lunr "$playbook_yml"
