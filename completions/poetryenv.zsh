#compdef poetryenv
# Zsh completion for poetryenv

_poetryenv_install() {
    _arguments \
        '--list[List all available versions from PyPI]' \
        '-l[List all available versions from PyPI]'
}

_poetryenv_versions() {
    _arguments \
        '--bare[Print only the version numbers]' \
        '-b[Print only the version numbers]'
}

_poetryenv_uninstall() {
    _arguments \
        '(-f --force)'{-f,--force}'[Skip confirmation prompts]' \
        '1:version:_poetryenv_version_options'
}

_poetryenv_version_options() {
    if command -v poetryenv &>/dev/null; then
        local -a versions
        versions=("${(@f)$(poetryenv versions --bare 2>/dev/null)}")
        _describe 'version' versions && ret=0
    fi
}

_poetryenv() {
    local line state

    _arguments -C \
        '1: :->command' \
        '*::arg:->args'

    case $state in
        command)
            local -a subcommands
            subcommands=(
                'install:Install a specific poetry version'
                'uninstall:Uninstall a specific poetry version'
                'global:Set or show the global poetry version'
                'local:Set or show the local poetry version'
                'version:Show the currently active poetry version'
                'versions:List all installed poetry versions'
                'which:Show the path to the active poetry executable'
                'help:Show help information'
            )
            _describe 'command' subcommands
            ;;
        args)
            case $words[1] in
                install)
                    _poetryenv_install
                    ;;
                versions)
                    _poetryenv_versions
                    ;;
                uninstall)
                    _poetryenv_uninstall
                    ;;
                global|local)
                    _poetryenv_version_options
                    ;;
            esac
            ;;
    esac
}

if type compdef &>/dev/null; then
    compdef _poetryenv poetryenv
fi
