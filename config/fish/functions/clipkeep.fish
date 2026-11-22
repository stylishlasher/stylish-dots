function clipkeep --description 'Clipboard history helper'
    if test -x "$HOME/.local/bin/clipkeep"
        "$HOME/.local/bin/clipkeep" $argv
    else if test -x /usr/local/bin/clipkeep
        /usr/local/bin/clipkeep $argv
    else
        echo "clipkeep not found"; return 1
    end
end
