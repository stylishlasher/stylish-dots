# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
    end
    
    # Colors
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    alias please 'sudo'
    alias .. 'cd ..'
    alias ... 'cd ../..'
    alias .... 'cd ../../..'
    alias gs 'git status -sb'
    alias ga 'git add'
    alias gc 'git commit'
    alias gp 'git push'
    alias gl 'git log --oneline --decorate -20'
    alias gdiff 'git diff'
    alias myip 'curl -fsS ifconfig.me'
    alias ports 'ss -tulpn'
    alias path 'printf "%s\n" $PATH'
    if test "$TERM" != "linux"
        alias ls 'eza --icons=auto'
        alias ll 'eza -lah --icons=auto'
        alias lt 'eza --tree --level=2 --icons=auto'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
end
