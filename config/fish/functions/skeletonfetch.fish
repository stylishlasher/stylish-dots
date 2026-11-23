function skeletonfetch --description 'Stylish 3D skeleton key fetch (Rust)'
    if command -q skeletonfetch-bin
        command skeletonfetch-bin $argv
    else if test -x "$HOME/.local/bin/skeletonfetch"
        "$HOME/.local/bin/skeletonfetch" $argv
    else if test -x /usr/local/bin/skeletonfetch
        /usr/local/bin/skeletonfetch $argv
    else
        echo "skeletonfetch not found. Build via: cd config/fetches/stylish-fetches && cargo build --release"
    end
end
