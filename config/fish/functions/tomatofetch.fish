function tomatofetch --description 'Stylish 3D tomato fetch (Rust)'
    if command -q tomatofetch-bin
        command tomatofetch-bin $argv
    else if test -x "$HOME/.local/bin/tomatofetch"
        "$HOME/.local/bin/tomatofetch" $argv
    else if test -x /usr/local/bin/tomatofetch
        /usr/local/bin/tomatofetch $argv
    else
        echo "tomatofetch not found. Build via: cd config/fetches/stylish-fetches && cargo build --release"
    end
end
