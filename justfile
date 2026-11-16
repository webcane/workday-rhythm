default: check

_package:
    @test -f Package.swift || { echo 'Не найден Package.swift: сначала создайте каркас SwiftPM.' >&2; exit 1; }

fmt: _package
    ./scripts/swift.sh format format --in-place --recursive Package.swift Sources Tests

lint: _package
    ./scripts/swift.sh format lint --strict --recursive Package.swift Sources Tests

names: _package
    ./scripts/check-names.sh

build: _package
    ./scripts/swift.sh build

test: _package
    ./scripts/swift.sh test

check: lint names build test
