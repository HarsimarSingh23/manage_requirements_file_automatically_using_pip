pip_wrapper() {
    if [ $# -eq 0 ]; then
        echo "Usage: pip <command> [package] [options]"
        return 1
    fi

    no_track=false
    cmd=$1
    shift

    clean_args=()
    for arg in "$@"; do
        if [ "$arg" = "-n" ]; then
            no_track=true
        else
            clean_args+=("$arg")
        fi
    done

    case "$cmd" in
        install)
            if [[ " ${clean_args[*]} " =~ " -r " ]] || [[ " ${clean_args[*]} " =~ " --requirement " ]]; then
                command pip install "${clean_args[@]}"
                return $?
            fi

            command pip install "${clean_args[@]}"
            if [ $? -ne 0 ]; then return 1; fi

            if [ "$no_track" = false ]; then
                touch requirements.txt
                for arg in "${clean_args[@]}"; do
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
            fi
            ;;
        uninstall)
            command pip uninstall "${clean_args[@]}"
            if [ $? -ne 0 ]; then return 1; fi

            if [ "$no_track" = false ]; then
                touch requirements.txt
                for arg in "${clean_args[@]}"; do
                    if [[ "$arg" == -* ]]; then continue; fi
                    sed -i.bak "/^${arg}==/Id" requirements.txt
                    echo "❌ Removed $arg from requirements.txt"
                done
            fi
            ;;
        *)
            command pip "$cmd" "${clean_args[@]}"
            ;;
    esac
}
alias pip="pip_wrapper"
