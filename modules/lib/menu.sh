#!/usr/bin/env bash
# Menu helpers for stylish-dots (GUI/TUI-lite in terminal).

MENU_CHOICE=""

menu_select() {
    local title="$1"; shift
    local -a items=("$@")
    local i
    while true; do
        echo
        echo -e "${BOLD}${CYAN}== $title ==${NC}"
        for i in "${items[@]}"; do
            local k="${i%%|*}"; local v="${i#*|}"
            echo -e "  ${GREEN}${k})${NC} $v"
        done
        local c
        read -rp "$(t choice): " c
        for i in "${items[@]}"; do
            local k="${i%%|*}"
            if [[ "$c" == "$k" ]]; then MENU_CHOICE="$c"; return 0; fi
        done
        warn "$(t invalid_choice)"
    done
}

# Checkbox selector: args "id|desc|on" or "id|desc|off"; returns selected ids in SELECTED_PACKAGES
SELECTED_PACKAGES=()
select_packages() {
    local title="$1"; shift
    local -a items=("$@")
    local -a on=()
    local i line id desc def
    for line in "${items[@]}"; do
        IFS='|' read -r id desc def _ <<<"$line"
        [[ "$def" == "on" ]] && on+=("1") || on+=("0")
    done

    while true; do
        echo
        echo -e "${BOLD}${CYAN}== $title ==${NC}"
        for i in "${!items[@]}"; do
            IFS='|' read -r id desc _ <<<"${items[$i]}"
            local mark="[ ]"; [[ "${on[$i]}" == "1" ]] && mark="[x]"
            printf "  %2d) %s %-28s %s\n" "$((i+1))" "$mark" "$id" "$desc"
        done
        echo "$(t checkbox_keys)"
        local c; read -rp "$(t toggle_prompt): " c
        case "$c" in
            a|A) for i in "${!on[@]}"; do on[$i]="1"; done ;;
            n|N) for i in "${!on[@]}"; do on[$i]="0"; done ;;
            d|D|"")
                SELECTED_PACKAGES=()
                for i in "${!items[@]}"; do
                    IFS='|' read -r id desc _ <<<"${items[$i]}"
                    [[ "${on[$i]}" == "1" ]] && SELECTED_PACKAGES+=("$id")
                done
                return 0
                ;;
            q|Q) SELECTED_PACKAGES=(); return 1 ;;
            *)
                if [[ "$c" =~ ^[0-9]+$ ]] && (( c>=1 && c<=${#items[@]} )); then
                    local idx=$((c-1))
                    [[ "${on[$idx]}" == "1" ]] && on[$idx]="0" || on[$idx]="1"
                else
                    warn "$(t invalid_input)"
                fi
                ;;
        esac
    done
}

# Single select: args "id|desc"; sets MENU_CHOICE to selected id
select_one() {
    local title="$1"; shift
    local -a items=("$@")
    local -a menu_items=()
    local line id desc
    for line in "${items[@]}"; do
        IFS='|' read -r id desc _ <<<"$line"
        menu_items+=("$id|$desc")
    done
    menu_select "$title" "${menu_items[@]}"
}
