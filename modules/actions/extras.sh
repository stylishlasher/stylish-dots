#!/usr/bin/env bash

action_create_home_readme() {
    local f="$HOME/README.md"
    [[ -e "$f" || -L "$f" ]] && stash_dir "$f"
    cat > "$f" <<'MD'
<!-- stylish-dots:home-readme -->
# Полезные ссылки

## Обои
- [Wallpaper Pack 25 (TMS Wallpapers) — 4K 3840x2160](https://forums.tms.sx/threads/wallpaper-pack-25-tms-wallpapers-4k-3840x2160-1-1000.40932/)

## Firefox расширения
- [Dark Reader](https://addons.mozilla.org/ru/firefox/addon/darkreader/)
- [uBlock Origin](https://addons.mozilla.org/ru/firefox/addon/ublock-origin/)
- [DuckDuckGo Privacy Essentials](https://addons.mozilla.org/ru/firefox/addon/duckduckgo-for-firefox/)
- [Privacy Badger](https://addons.mozilla.org/ru/firefox/addon/privacy-badger17/)
- [SponsorBlock](https://addons.mozilla.org/ru/firefox/addon/sponsorblock/)
MD
    ok "Создан $f"
}
