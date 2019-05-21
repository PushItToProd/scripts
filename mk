#!/usr/bin/env bash
THIS="$(basename "$0")"
USAGE="usage: $0 FILE...

A utility for quick and easy file creation. Each argument should be a path. Each
given path that does not exist will be created as a directory if it ends in a
slash or otherwise as a normal file.

NEW FILE TEMPLATES

New files created matching certain patterns will be pre-populated as follows.

- Files named main.go will have 'package main' on their first line.
- Files matching *.sh will have '#!/usr/bin/env bash' on their first line.
- Files matching *.bats will have '#!/usr/bin/env bats' on their first line.

SPECIAL CASES

If $THIS is invoked from the GoLand terminal with a file matching *.go, the file
will be opened in GoLand."

file_is_empty() {
    # -s tests if the file is not zero size
    [[ ! -s "$1" ]]
}

# Special cases to execute regardless of whether the file was created.
post_run() {
    local -r path="$1"
    case "$(basename "$path")" in
        *.go)
            if [[ "$SNAP_NAME" == "goland" ]]; then
                goland "$path" >/dev/null
            fi
            ;;
    esac
}

# Special cases to execute only if we created a new file.
post_create() {
    local -r path="$1"
    case "$(basename "$path")" in
        main.go)
            echo "package main" >"$path"
            ;;
        *.sh)
            echo "#!/usr/bin/env bash" >"$path"
            ;;
        *.bats)
            echo "#!/usr/bin/env bats" >"$path"
            ;;
    esac
}

# mkdir -p if the path ends with a slash, touch if not.
create_file() {
    local -r path="$1"

    FILE_EXISTED=0
    if [[ -e "$path" ]]; then
        FILE_EXISTED=1
    fi

    if [[ "$path" == */ ]]; then
        mkdir -p "$path"
    else
        mkdir -p "$(dirname "$path")"
        touch "$path"
    fi

    post_run "$path"

    if [[ FILE_EXISTED == "1" ]]; then
        return 0
    fi

    post_create "$path"
}

main() {
    for f in "$@"; do
        if [[ "$f" == "-help" ]]; then
            echo "$USAGE"
            exit 0
        fi
    done
    for f in "$@"; do
        create_file "$f"
    done
}
main "$@"
