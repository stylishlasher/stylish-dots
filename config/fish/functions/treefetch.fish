function treefetch --description 'Stylish 3D tree fetch (Rust)'
    if command -q treefetch-bin
        command treefetch-bin $argv
    else if test -x "$HOME/.local/bin/treefetch"
        "$HOME/.local/bin/treefetch" $argv
    else if test -x /usr/local/bin/treefetch
        /usr/local/bin/treefetch $argv
    else
        echo "treefetch not found. Build via: cd config/fetches/stylish-fetches && cargo build --release"
    end
end
