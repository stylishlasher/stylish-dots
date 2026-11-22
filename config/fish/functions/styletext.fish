function styletext --description 'Render text as ASCII art'
    if command -q styletext-bin
        command styletext-bin $argv
    else if test -x "$HOME/.local/bin/styletext"
        "$HOME/.local/bin/styletext" $argv
    else if test -x /usr/local/bin/styletext
        /usr/local/bin/styletext $argv
    else
        echo "styletext not found. Install via multitool or place in ~/.local/bin/styletext"
        return 1
    end
end
