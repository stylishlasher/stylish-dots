function converttool --description 'File converter (ffmpeg/imagemagick/pandoc/libreoffice)'
    set -l bin ""
    if test -x "$HOME/.local/bin/converttool"
        set bin "$HOME/.local/bin/converttool"
    else if test -x /usr/local/bin/converttool
        set bin /usr/local/bin/converttool
    else if test -x "$HOME/stylish-dots/config/bin/converttool"
        set bin "$HOME/stylish-dots/config/bin/converttool"
    end

    if test -z "$bin"
        echo "converttool not found. Install stylish-dots bin scripts or run from repo config/bin/converttool." >&2
        return 127
    end

    if contains -- -h $argv; or contains -- --help $argv; or test (count $argv) -eq 0
        $bin --help
        echo
        echo "Fish shortcuts:"
        echo "  converttool *.png .webp --batch"
        echo "  converttool media/ .mp3 --batch -r -o converted"
        echo "  converttool input.mp4 .gif --resize 640:-1 --fps 12"
        echo "  converttool doc.md .pdf"
        return 0
    end

    $bin $argv
end
