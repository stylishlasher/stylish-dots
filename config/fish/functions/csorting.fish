function csorting --description 'Ambient sorting visualizer (dots or bars)'
    if command -q csorting-bin
        command csorting-bin $argv
    else if test -x "$HOME/.local/bin/csorting"
        "$HOME/.local/bin/csorting" $argv
    else if test -x /usr/local/bin/csorting
        /usr/local/bin/csorting $argv
    else
        echo "csorting not found. Install via multitool or place in ~/.local/bin/csorting"
        return 1
    end
end
