# Workday Rhythm

Каркас нативного приложения для macOS 13 и новее. Требуется Swift 6 и macOS SDK. Для `swift test` нужен полный Xcode: Command Line Tools могут собрать приложение, но не содержат XCTest. Дневная программа и таймер пока не реализованы.

## Компоненты

| Target | Назначение | Разрешённые зависимости |
|---|---|---|
| Program | Модели программы | нет |
| TimerEngine | Чистое ядро таймера | Program |
| SettingsStore | Граница UserDefaults | Program |
| MacIntegration | Системные адаптеры macOS | нет |
| SessionCoordinator | Связывание ядра и адаптеров | Program, TimerEngine, SettingsStore, MacIntegration |
| Presentation | Строка меню и окно настроек | SessionCoordinator |
| WorkdayRhythmApp | Создание зависимостей и жизненный цикл | Presentation, SessionCoordinator, SettingsStore, MacIntegration |

Program и TimerEngine не зависят от AppKit или SwiftUI. Presentation обращается к остальным компонентам через SessionCoordinator. Сторонних пакетов нет.

## Разработка

```sh
swift package dump-package
swift build
swift test
swift run WorkdayRhythmApp
```

Если `xcode-select -p` указывает на Command Line Tools, выбирайте установленный Xcode для команды через переменную окружения (без изменения системных настроек):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

`swift test` проверяет граф targets из manifest и импорты исходников. Отдельная проверка подставляет запрещённые зависимости и импорты и убеждается, что правило их обнаруживает.

Запуск приложения требует графического сеанса macOS. Команда `swift run` запускает процесс разработки без релизного `.app`: упаковка, подпись, установка и автозапуск не входят в каркас.

Если окружение ограничивает запись в пользовательские кеши SwiftPM, используйте для каждой команды Swift:

```sh
CLANG_MODULE_CACHE_PATH=/tmp/workday-clang-cache \
SWIFTPM_MODULECACHE_OVERRIDE=/tmp/workday-swift-cache \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
swift build --disable-sandbox --cache-path /tmp/workday-spm-cache
```

Для остальных команд замените `build` на `test`, `run WorkdayRhythmApp` или `package dump-package`, сохранив параметры SwiftPM.

## Проверка оболочки

После запуска найдите значок Workday Rhythm в строке меню. Откройте «Настройки», закройте окно и откройте его снова. Выберите «Выход»: значок должен исчезнуть, а команда запуска — завершиться.

Проверено 16 ноября 2026 года с Xcode Swift 6.3.3: manifest не содержит внешних пакетов, сборка проходит, три архитектурных теста проходят. Временные изменения `Presentation → TimerEngine` и `import AppKit` в Program обнаруживаются проверкой; после проверки файлы восстановлены. `swift run WorkdayRhythmApp` запускает процесс в графическом сеансе. Пользователь вручную подтвердил наличие значка и меню, русский текст настроек, повторное открытие окна после закрытия и исчезновение значка после «Выход». Команда запуска завершилась успешно. Автоматизированный доступ к интерфейсу в окружении проверки не разрешён.
