function quicknote --description 'Append/search quick notes'
    if test -x "$HOME/.local/bin/quicknote"
        "$HOME/.local/bin/quicknote" $argv
    else if test -x /usr/local/bin/quicknote
        /usr/local/bin/quicknote $argv
    else
        set -l f ~/Notes/quicknotes.md
        mkdir -p (dirname $f)
        if test (count $argv) -eq 0
            ${EDITOR:-nvim} $f
        else
            echo "- ["(date '+%Y-%m-%d %H:%M')"] $argv" >> $f
            echo $f
        end
    end
end
