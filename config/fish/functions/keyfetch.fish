function keyfetch --description 'Stylish 3D key fetch (Rust)'
    if command -q keyfetch-bin
        command keyfetch-bin $argv
    else if test -x "$HOME/.local/bin/keyfetch"
        "$HOME/.local/bin/keyfetch" $argv
    else if test -x /usr/local/bin/keyfetch
        /usr/local/bin/keyfetch $argv
    else
        echo "keyfetch not found. Build via: cd config/fetches/stylish-fetches && cargo build --release"
    end
end
