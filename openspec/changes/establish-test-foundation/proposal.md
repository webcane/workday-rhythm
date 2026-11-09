# Proposal

## Why

Каркасу Workday Rhythm нужен воспроизводимый способ запускать тесты с первого изменения Swift-кода. Первые проверки должны ловить нарушения границ модулей и ошибки в привязке команд меню.

## What Changes

- Зарегистрировать тестовые targets в SwiftPM, разместить тесты по модулям в `Tests/` и описать запуск из корня через `swift test`.
- Добавить проверки границ модулей и маршрутизации команд «Настройки» и «Выход» без запуска приложения.
- Использовать `swift test` в запланированном рецепте `just test`, который входит в `just check`.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

Изменение зависит от `scaffold-macos-app-architecture` и затрагивает будущие `Package.swift`, `Tests/`, `README.md` и связывание команд в `Presentation`. Поведение оболочки задано в `application-shell`. Интеграция с `just check` использует рецепт из `establish-swift-code-quality`.
