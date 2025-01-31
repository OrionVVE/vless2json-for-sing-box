# vless2json-for-sing-box
Automatically convert vless string format (vless:// or https://) to json configuration format for Sing-box

# Dependencies
Before using the URI to JSON scripts, ensure you have the following softwares installed:
- `jq`
- `base64` (coreutils)
- `awk`

Основанно на проекте https://github.com/ImanSeyed/v2ray-uri2json
Скрипт переписан для консоли OpenWRT (sh)
Скрипт автоматически формирует конфигурационный файл json для SING-BOX из строки типа vless://... или https://...
```shell
$ bash scripts/vless2json.sh <URI> # For vless URI
```
