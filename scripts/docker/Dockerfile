FROM alpine:3.21

# includes dependencies from https://git.alpinelinux.org/aports/tree/main/fuse3/APKBUILD
RUN apk add --no-cache \
    bash alpine-sdk util-linux strace file autoconf automake libtool xz \
    eudev-dev gettext-dev linux-headers meson \
    zstd-dev zstd-static zlib-dev zlib-static clang musl-dev mimalloc-dev

# the whole directory: with install-dependencies.sh, the downloads/ that
# download-with-gh.sh may have filled on the CI runner
COPY scripts/common/ /tmp/scripts/common/
COPY patches/ /tmp/patches/

WORKDIR /tmp
RUN bash scripts/common/install-dependencies.sh
