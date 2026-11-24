# modules/

🇷🇺 [Русский](../README.md) · 🇬🇧 [English](README.en.md) · 🇷🇴 Română

Sistemul modular al stylish-dots. Utilitarele (`arch_multitool.sh`, `arch_multitool_debian.sh`) se ocupă de interfață/meniu, iar acțiunile sunt în module.

## Structură

- `lib/` — helperi comuni:
  - `common.sh` — logare, sudo, resolve_configs, backup/normalize
  - `platform.sh` — detectarea platformei și pkg_install/pkg_update
  - `menu.sh` — menu_select/select_packages
  - `loader.sh` — descărcarea/încărcarea modulelor, run_action
- `actions/` — acțiuni:
  - `interactive.sh` — instalare completă: asistent în patru pași
  - `software.sh` — meniul de programe
  - `extras.sh` — SDDM, Caelestia, cursoare Bibata, monitoare, ștergerea cache-ului
  - `dotfiles.sh` — aplicarea profilurilor/configurărilor
  - `fish.sh`, `neovim.sh`, `fetches.sh`, `flatpak.sh`, `network.sh`, `system.sh`, `audit.sh`

## Cum funcționează

La pornirea utilitarului, acesta încarcă `lib/*`. Când utilizatorul alege o acțiune, `run_action` încarcă `actions/*.sh` corespunzător. Dacă modulul nu există local (de exemplu la `curl | bash`), loaderul îl descarcă de la `https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/modules/...`.

## Extindere

Adaugă o acțiune nouă în `modules/actions/<name>.sh`, exportă funcția `action_*` și înregistreaz-o în `modules/lib/loader.sh`, în `run_action`.
