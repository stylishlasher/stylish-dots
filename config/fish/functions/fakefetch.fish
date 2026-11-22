function fakefetch --description 'Fake fastfetch/neofetch for a distro'
    if command -q fakefetch-bin
        command fakefetch-bin $argv
    else if test -x "$HOME/.local/bin/fakefetch"
        "$HOME/.local/bin/fakefetch" $argv
    else if test -x /usr/local/bin/fakefetch
        /usr/local/bin/fakefetch $argv
    else
        echo "fakefetch not found. Install via multitool or place in ~/.local/bin/fakefetch"
        return 1
    end
end
