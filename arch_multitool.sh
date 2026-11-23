#!/usr/bin/env bash
set -uo pipefail
TOOL_NAME="Arch Multitool v4"
STYLISH_PLATFORM="arch"
export STYLISH_PLATFORM
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/modules/lib/multitool.sh" ]]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/modules/lib/multitool.sh"
else
    tmp="$(mktemp /tmp/stylish-multitool.XXXXXX)"
    curl -fsSL "https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/modules/lib/multitool.sh" -o "$tmp" || exit 1
    # shellcheck disable=SC1090
    source "$tmp"
fi
multitool_main "$@"
