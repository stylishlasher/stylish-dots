function extract --description 'Extract archives by extension'
    if test (count $argv) -lt 1
        echo "Usage: extract <archive>"; return 1
    end
    for f in $argv
        switch $f
            case '*.tar.bz2' '*.tbz2'; tar xjf $f
            case '*.tar.gz' '*.tgz'; tar xzf $f
            case '*.tar.xz' '*.txz'; tar xJf $f
            case '*.tar.zst'; tar --zstd -xf $f
            case '*.tar'; tar xf $f
            case '*.bz2'; bunzip2 $f
            case '*.gz'; gunzip $f
            case '*.xz'; unxz $f
            case '*.zip'; unzip $f
            case '*.7z'; 7z x $f
            case '*.rar'; unrar x $f
            case '*.zst'; unzstd $f
            case '*'; echo "extract: unknown format: $f"
        end
    end
end
