function stoolfetch --description 'Stylish 3D stool fetch (Rust)'
    if command -q stoolfetch-bin
        command stoolfetch-bin $argv
    else if test -x "$HOME/.local/bin/stoolfetch"
        "$HOME/.local/bin/stoolfetch" $argv
    else if test -x /usr/local/bin/stoolfetch
        /usr/local/bin/stoolfetch $argv
    else
        echo "stoolfetch not found. Build via: cd config/fetches/stylish-fetches && cargo build --release"
    end
end
