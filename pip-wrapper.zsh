pip_wrapper() {
    if [ $# -eq 0 ]; then
        echo "Usage: pip <command> [package] [options]"
        return 1
    fi

    cmd=$1
    shift

    case "$cmd" in
        install)
            if [[ " $@ " =~ " -r " ]] || [[ " $@ " =~ " --requirement " ]]; then
                command pip install "$@"
                return $?
            fi

            command pip install "$@"
            if [ $? -ne 0 ]; then return 1; fi

            touch requirements.txt
            for arg in "$@"; do
                if [[ "$arg" == -* ]]; then continue; fi
                pkg=$(pip show "$arg" 2>/dev/null | grep -i "Name: " | awk '{print $2}')
                ver=$(pip show "$arg" 2>/dev/null | grep -i "Version: " | awk '{print $2}')
                if [ -n "$pkg" ] && [ -n "$ver" ]; then
                    line="${pkg}==${ver}"
                    sed -i.bak "/^${pkg}==/Id" requirements.txt
                    echo "$line" >> requirements.txt
                    echo "✅ Added/Updated $line in requirements.txt"
                fi
            done
            sort -u -o requirements.txt requirements.txt
            ;;
        uninstall)
            command pip uninstall "$@"
            if [ $? -ne 0 ]; then return 1; fi
            touch requirements.txt
            for arg in "$@"; do
                if [[ "$arg" == -* ]]; then continue; fi
                sed -i.bak "/^${arg}==/Id" requirements.txt
                echo "❌ Removed $arg from requirements.txt"
            done
            ;;
        *)
            command pip "$cmd" "$@"
            ;;
    esac
}
alias pip="pip_wrapper"
