# Sa1zy TikTok Visual Mod (iOS)

## Файлы проекта
- Tweak.x — исходный код хуков (Logos/Objective-C) под AWEUserModel и жест вызова меню
- Makefile — конфиг сборщика Theos
- control — метаданные пакета Debian
- .github/workflows/build.yml — GitHub Actions автосборка dylib

## Как запустить сборку:
1. Залить папку в репозиторий на GitHub.
2. Перейти в Actions -> запустить workflow.
3. Скачать Sa1zyTikTokMod.dylib из Artifacts.
4. Внедрить в TikTok.ipa через Sideloadly (Advanced Options -> Inject dylib).
