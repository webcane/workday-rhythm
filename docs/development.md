# Разработка

## Первые шаги

1. Установите полный Xcode 26.6 со Swift 6.3.3 и завершите его первоначальную настройку. Нужны macOS 13+ и macOS SDK; для XCTest отдельного пакета Command Line Tools недостаточно.
2. Для локальных команд установите `just` 1.59.0 через Homebrew: `brew install just`, затем проверьте `just --version`. CI не использует `just`.
3. Откройте терминал в корне репозитория, рядом с `Package.swift`. Внешних Swift-пакетов нет.
4. Выполните команды из следующего раздела: проверьте manifest, запустите общую проверку, затем приложение.
5. Ознакомьтесь со [стилем Swift](code-style.md), [архитектурой](architecture.md) и [правилами тестирования](testing.md). Планируемые изменения находятся в `openspec/changes/`.

## Подход к разработке: SDD и OpenSpec

В проекте используется SDD (Spec-Driven Development): реализация опирается на согласованные спецификации поведения. Для ведения спецификаций и изменений используется OpenSpec; конфигурация проекта находится в `openspec/config.yaml`.

Работа над изменением проходит последовательно:

1. В `proposal.md` фиксируются проблема, цель и границы изменения.
2. В `specs/` описываются требования и наблюдаемые сценарии; в `design.md` — технические решения и ограничения.
3. В `tasks.md` формируется проверяемый список задач. Код реализуется по этим задачам, а выполнение отмечается после проверки результата.
4. После реализации проверяется соответствие спецификациям. Завершённое изменение архивируется, а изменения требований переносятся в основные спецификации.

Рабочие материалы хранятся в `openspec/changes/<change>/`, основные спецификации — в `openspec/specs/` по мере их публикации. Состав артефактов определяется схемой конкретного изменения: для изменений инструментов спецификации пользовательского поведения могут не требоваться. Если решение меняется при реализации, сначала актуализируются затронутые артефакты, затем код.

## Команды

```sh
./scripts/swift.sh package dump-package
just check
./scripts/swift.sh run WorkdayRhythmApp
```

`just check` последовательно выполняет строгий `swift-format` lint, проверку имён Swift-файлов, сборку и XCTest. Команда ничего не исправляет и останавливается при первой ошибке. Для автоматического исправления форматирования используйте `just fmt`, затем повторите `just check`. Отдельные рецепты `just lint`, `just names`, `just build` и `just test` удобны при локальной работе. `just` используется только локально; CI запускает эти проверки прямыми командами `swift format lint --strict --recursive Package.swift Sources Tests`, `./scripts/check-names.sh`, `swift build` и `swift test`.

Скрипт запускает Swift из выбранного Xcode. Если `xcode-select -p` указывает на Command Line Tools, он использует `/Applications/Xcode.app/Contents/Developer` только для текущей команды. Явный `DEVELOPER_DIR` имеет приоритет; для Xcode в другом каталоге задайте его самостоятельно. Скрипт не меняет глобальные настройки.

Для обычных команд `swift build`, `swift test` и `swift run WorkdayRhythmApp` сначала выберите полный Xcode. Однократная настройка системы (выполняется пользователем с правами администратора):

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
xcode-select -p
swift test
```

`xcode-select -p` должен показать `/Applications/Xcode.app/Contents/Developer`. Ошибка `no such module 'XCTest'` при выбранном `/Library/Developer/CommandLineTools` означает, что используется комплект без XCTest, а не падение тестовых assertions. Установка Xcode сама по себе не меняет активный developer directory.

Для разового запуска без скрипта и без изменения системных настроек:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

Запуск приложения требует графического сеанса macOS. Команда `swift run` запускает процесс разработки без релизного `.app`: упаковка, подпись, установка и автозапуск не входят в каркас.

Если окружение ограничивает запись в пользовательские кеши SwiftPM, используйте для каждой команды Swift:

```sh
CLANG_MODULE_CACHE_PATH=/tmp/workday-clang-cache \
SWIFTPM_MODULECACHE_OVERRIDE=/tmp/workday-swift-cache \
./scripts/swift.sh build --disable-sandbox --cache-path /tmp/workday-spm-cache
```

Для тестов замените `build` на `test`. Для запуска используйте `./scripts/swift.sh run --disable-sandbox --cache-path /tmp/workday-spm-cache WorkdayRhythmApp` с теми же переменными кеша. Настройка кешей и `--disable-sandbox` нужны только в ограниченном окружении агента, а не для обычного локального запуска.

## Перед завершением изменения

Выполните `just check`, затем `git diff --check`. Для изменений оболочки пройдите [ручной сценарий](testing.md#ручная-проверка-оболочки). В отчёте укажите точную команду, toolchain, результаты автоматических и ручных проверок и ограничения окружения.
