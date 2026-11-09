#! /bin/bash

# Runs on the GitHub Actions runner, before the build (Docker, chroot or Debian ports):
# downloads the files that install-dependencies.sh fetches from GitHub, with the token
# of the workflow, into scripts/common/downloads/. Authenticated requests do not suffer
# when GitHub throttles anonymous ones (e.g. "504 Gateway Time-out").
# install-dependencies.sh uses these files when they are there and falls back to wget
# otherwise, and checks their checksums either way, so a failure here is not fatal.
#
# The list of files comes from the "fetch <file> <url>" lines of install-dependencies.sh.
#
# Usage: env GH_TOKEN=... bash scripts/common/download-with-gh.sh

set -uo pipefail

this_dir="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"
downloads="$this_dir"/downloads
mkdir -p "$downloads"

if ! command -v gh >/dev/null || [[ "${GH_TOKEN:-}" == "" ]]; then
    echo "gh or GH_TOKEN not available: install-dependencies.sh will download with wget"
    exit 0
fi

# retry, as authenticated requests can time out as well
retry() {
    local i
    for i in 1 2 3 4 5; do
        "$@" && return 0
        echo "attempt $i failed: $*" >&2
        sleep $((i * 10))
    done
    return 1
}

download() {
    local file="$1" url="$2"
    if [[ "$url" =~ ^https://github\.com/([^/]+/[^/]+)/releases/download/([^/]+)/([^/]+)$ ]]; then
        # release asset
        gh release download "${BASH_REMATCH[2]}" -R "${BASH_REMATCH[1]}" -p "${BASH_REMATCH[3]}" \
            -O "$downloads/$file" --clobber
    elif [[ "$url" =~ ^https://github\.com/([^/]+/[^/]+)/archive/(.+)\.tar\.gz$ ]]; then
        # source archive: codeload serves the same bytes as the archive URL (the
        # tarball of the API has another top directory, hence another checksum)
        curl -fsSL -H "Authorization: Bearer $GH_TOKEN" \
            -o "$downloads/$file" "https://codeload.github.com/${BASH_REMATCH[1]}/tar.gz/${BASH_REMATCH[2]}"
    else
        echo "not a GitHub URL, left to wget: $url"
        return 0
    fi
}

grep -E '^fetch ' "$this_dir"/install-dependencies.sh | while read -r _ file url; do
    retry download "$file" "$url" || rm -f "$downloads/$file"
done

ls -l "$downloads"
exit 0
