#!/usr/bin/env bash
# Bash completion for poetryenv
#
# To enable:
#   source /path/to/poetryenv/completions/poetryenv.bash
#
# Or add to ~/.bashrc or ~/.bash_profile:
#   if command -v poetryenv 1>/dev/null 2>&1; then
#     eval "$(poetryenv init - bash)"
#   fi

_poetryenv() {
    local cur prev command
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD - 1]}"
    command="${COMP_WORDS[1]}"

    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=($(compgen -W "install uninstall global local version versions which --help -h" -- "${cur}"))
        return 0
    fi

    case "${command}" in
    install)
        COMPREPLY=($(compgen -W "--list -l" -- "${cur}"))
        ;;
    versions)
        COMPREPLY=($(compgen -W "--bare -b" -- "${cur}"))
        ;;
    uninstall)
        if [[ "${cur}" == -* ]]; then
            COMPREPLY=($(compgen -W "--force -f" -- "${cur}"))
        else
            local versions=$(poetryenv versions --bare 2>/dev/null)
            COMPREPLY=($(compgen -W "${versions}" -- "${cur}"))
        fi
        ;;
    global | local)
        local versions=$(poetryenv versions --bare 2>/dev/null)
        COMPREPLY=($(compgen -W "${versions}" -- "${cur}"))
        ;;
    *)
        COMPREPLY=()
        ;;
    esac

    return 0
}

complete -F _poetryenv poetryenv
