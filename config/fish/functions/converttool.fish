function converttool --description 'Simple file converter (ffmpeg/imagemagick/pandoc)'
    if test -x "$HOME/.local/bin/converttool"
        "$HOME/.local/bin/converttool" $argv
    else if test -x /usr/local/bin/converttool
        /usr/local/bin/converttool $argv
    else
        echo "Usage: converttool input output(.ext)"; return 1
    end
end
