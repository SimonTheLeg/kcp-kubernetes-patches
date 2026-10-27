#!/usr/bin/env bash

set -euo pipefail

log() { echo ">>> $*"; }
die() { log "$@"; exit 1; }
cd "$(dirname $0)/.."
source ./hack/lib.bash

# if generation of patches fails
restore_patches() {
    if [[ "$?" -ne 0 ]]; then
        log "Formatting failed, restoring patches/"
        git restore -- patches/
        git clean -f -- patches/
    fi
}

format_patches() {
    local base_ref="${1:-}"
    if [[ -z "$base_ref" ]]; then
        die "Usage: format_patches <ref>"
    fi

    trap restore_patches EXIT

    rm -f patches/*.patch
    (
        cd kubernetes/
        git format-patch \
            --no-numbered \
            --no-thread \
            --no-cover-letter \
            --zero-commit \
            --signature='' \
            --text \
            --output-directory=../patches \
            "kubernetes/v${base_ref}..kcp-dev/kcp-${base_ref}"

        # remove the "carry: drop: ..." commits; matching the leading
        # patch counter is required since some commits contain "drop" or
        # every "carry..drop"
        find ../patches -iregex '.*/[0-9]*-carry-drop-.*' -delete
    )
}

format_patches "$@"
