#!/bin/bash
set -euo pipefail

TARGET="${1:-all}"
KERNEL_REPO="https://gitlab.com/vanadium-oss/sdm845/samsung/galaxysdm845/Trees/android_kernel_samsung_sdm845.git"
KERNEL_BRANCH="lineage-22.2"
CLANG_DIR="$HOME/toolchains/clang-r487747c"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$CLANG_DIR/bin/clang" ]; then
    mkdir -p "$CLANG_DIR"
    curl -LSs "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/android14-release/clang-r487747c.tar.gz" | tar -xz -C "$CLANG_DIR"
fi

export PATH="$CLANG_DIR/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export CC_ARM32=arm-linux-gnueabi-gcc

if [ ! -d "kernel" ]; then
    git clone -b "$KERNEL_BRANCH" "$KERNEL_REPO" --depth=1 kernel
fi

cd kernel

mkdir -p ../output

build_device() {
    local dev="$1"
    local cfg="$2"
    rm -rf out && mkdir -p out
    make O=out CC="clang" CC_ARM32="arm-linux-gnueabi-gcc" sdm845_defconfig "$cfg"
    make O=out CC="clang" CC_ARM32="arm-linux-gnueabi-gcc" olddefconfig
    make -j"$(nproc --all)" O=out CC="clang" CC_ARM32="arm-linux-gnueabi-gcc" Image.gz-dtb
    cp out/arch/arm64/boot/Image.gz-dtb "../AnyKernel3/Image.gz-dtb"
    (
        cd ../AnyKernel3
        zip -r9 "../output/AnyKernel3-Lineage22.2-Ruby-$dev.zip" . -x ".git/*" ".github/*" "*.zip"
        rm -f Image.gz-dtb
    )
}

case "$TARGET" in
    starqltechn)
        build_device starqltechn starqlte_chn.config
        ;;
    star2qltechn)
        build_device star2qltechn star2qlte_chn.config
        ;;
    crownqltechn)
        build_device crownqltechn crownqlte_chn.config
        ;;
    all|*)
        build_device starqltechn starqlte_chn.config
        build_device star2qltechn star2qlte_chn.config
        build_device crownqltechn crownqlte_chn.config
        ;;
esac
