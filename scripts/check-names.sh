#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f Package.swift ]]; then
    echo 'Не найден Package.swift: сначала создайте каркас SwiftPM.' >&2
    exit 1
fi

status=0
name_pattern='^[A-Z][A-Za-z0-9]*$'

while IFS= read -r -d '' directory; do
    target=${directory##*/}
    if [[ ! $target =~ $name_pattern ]]; then
        echo "Неверное имя target-каталога: $directory (нужен UpperCamelCase)." >&2
        status=1
    fi
done < <(find Sources Tests -mindepth 1 -maxdepth 1 -type d -print0)

while IFS= read -r -d '' file; do
    filename=${file##*/}
    stem=${filename%.swift}

    case $file in
        Sources/*/*.swift)
            if [[ $filename != main.swift && ! $stem =~ $name_pattern ]]; then
                echo "Неверное имя Swift-файла: $file (нужен UpperCamelCase.swift)." >&2
                status=1
            fi
            ;;
        Tests/*/*.swift)
            if [[ ! $stem =~ $name_pattern || $stem != *Tests ]]; then
                echo "Неверное имя тестового файла: $file (нужен UpperCamelCaseTests.swift)." >&2
                status=1
            fi
            ;;
        *)
            echo "Swift-файл вне каталога target: $file." >&2
            status=1
            ;;
    esac
done < <(find Sources Tests -type f -name '*.swift' -print0)

exit "$status"
