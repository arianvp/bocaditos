# shellcheck shell=bash

fixupOutputHooks+=(patchSystemdUnits)

units=(service socket mount swap)
execs=(ExecStart ExecStartPre ExecStartPost ExecStop ExecStopPost ExecReload ExecRestart ExecCondition)

isSystemdUnit() {
    local f
    f=$1
    for unit in "${units[@]}"; do
        # should check if it's in $lib/systemd/system/ too
        if [[ "$f" == *".${unit}" ]]; then
            return 0
        fi
    done
    return 1
}

_patchSystemdUnits() {
    echo "patching systemd units in" "$@"
    local pathName
    local f
    local oldPath
    local newPath
    local newExec

    if [[ $# -eq 0 ]]; then
        echo "No arguments supplied to patchShebangs" >&2
        return 0
    fi

    local f
    while IFS= read -r -d $'\0' f; do
        isSystemdUnit "$f" || continue

        if [[ -n $strictDeps && $f == "$NIX_STORE"* ]]; then
            pathName=HOST_PATH
        else
            pathName=PATH
        fi

        for exec in "${execs[@]}"; do
            # go through each line in the file and replace the relative path with the absolute path

            # format is ExecStart=/path/to/executable args

            # NOTE: this currently doesn't handle quotes on the first argument. e.g.
            # ExecStart="hello world" args
            # would be incorrectly split into two arguments

            echo "Checking $f for $exec"
            if ! grep -q "^$exec=" "$f"; then
                continue
            fi
            # Extract all command names (handling possible multiple occurrences)
            while IFS= read -r oldPath; do
                # Resolve absolute path using PATH lookup
                newPath="$(PATH="${!pathName}:${!outputBin}/bin" type -P "$(basename "$oldPath")" || true)"

                # Check if we need to replace (ignore if already in NIX_STORE)
                if [[ -n "$oldPath" && "${oldPath:0:${#NIX_STORE}}" != "$NIX_STORE" ]]; then
                    if [[ -n "$newPath" && "$newPath" != "$oldPath" ]]; then
                        # Escape slashes for `sed`
                        escapedPath=${newPath//\//\\/}

                        # Preserve timestamps
                        timestamp=$(stat --printf "%y" "$f")

                        # Replace the old command with the new absolute path
                        sed -i -E "s|(${exec}=-?)${oldPath}|\1${escapedPath}|" "$f"

                        touch --date "$timestamp" "$f"
                    fi
                fi
            done < <(sed -n -E "s|^${exec}=-?([^[:space:]]+).*|\1|p" "$f")

            
        done
    done < <(find "$@" -type f -print0)
}

patchSystemdUnits () {
    if [[ -z "${dontPatchSystemdUnits-}" && -e "$prefix" ]]; then
        _patchSystemdUnits "$prefix"
    fi
}
