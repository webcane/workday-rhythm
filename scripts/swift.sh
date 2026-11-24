#!/bin/sh
set -eu

# XCTest входит в Xcode, но отсутствует в отдельном пакете Command Line Tools.
# Выбор действует только для текущей команды; явный DEVELOPER_DIR сохраняется.
if [ -z "${DEVELOPER_DIR:-}" ]; then
    developer_dir=$(xcode-select -p)
    case "$developer_dir" in
        */CommandLineTools)
            if [ ! -d /Applications/Xcode.app/Contents/Developer ]; then
                echo 'Для проекта нужен Xcode. Установите его и задайте DEVELOPER_DIR.' >&2
                exit 1
            fi
            DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
            export DEVELOPER_DIR
            ;;
    esac
fi

case "${1:-}" in
    build|test|run)
        command=$1
        shift
        cache_root="${TMPDIR:-/tmp}/workday-rhythm-swift-cache"
        : "${CLANG_MODULE_CACHE_PATH:=$cache_root/clang}"
        : "${SWIFTPM_MODULECACHE_OVERRIDE:=$cache_root/modules}"
        export CLANG_MODULE_CACHE_PATH SWIFTPM_MODULECACHE_OVERRIDE
        mkdir -p "$CLANG_MODULE_CACHE_PATH" "$SWIFTPM_MODULECACHE_OVERRIDE" "$cache_root/spm"
        exec /usr/bin/xcrun swift "$command" --disable-sandbox --cache-path "$cache_root/spm" "$@"
        ;;
    *)
        exec /usr/bin/xcrun swift "$@"
        ;;
esac
