#!/usr/bin/env bash
# Shared path helpers for Steam Headless startup and user scripts.

steam_headless_user_name() {
    printf '%s\n' "${USER:-${STEAM_HEADLESS_USER:-default}}"
}

steam_headless_user_home() {
    if [[ -n "${USER_HOME:-}" ]]; then
        printf '%s\n' "${USER_HOME}"
        return
    fi

    local user_name
    user_name="$(steam_headless_user_name)"
    getent passwd "${user_name}" | cut -d: -f6
}

steam_headless_games_dir() {
    printf '%s\n' "${GAMES_DIR:-/mnt/games}"
}

steam_headless_steam_library() {
    local games_dir
    games_dir="$(steam_headless_games_dir)"

    if [[ -n "${STEAM_LIBRARY_DIR:-}" ]]; then
        printf '%s\n' "${STEAM_LIBRARY_DIR}"
    elif compgen -G "${games_dir}/GameLibrary/SteamLibrary/steamapps/appmanifest_*.acf" >/dev/null; then
        printf '%s\n' "${games_dir}/GameLibrary/SteamLibrary"
    elif compgen -G "${games_dir}/SteamLibrary/steamapps/appmanifest_*.acf" >/dev/null; then
        printf '%s\n' "${games_dir}/SteamLibrary"
    elif compgen -G "${games_dir}/GameLibrary/Steam/steamapps/appmanifest_*.acf" >/dev/null; then
        printf '%s\n' "${games_dir}/GameLibrary/Steam"
    elif [[ -d "${games_dir}/GameLibrary/SteamLibrary/steamapps" ]]; then
        printf '%s\n' "${games_dir}/GameLibrary/SteamLibrary"
    elif [[ -d "${games_dir}/SteamLibrary/steamapps" ]]; then
        printf '%s\n' "${games_dir}/SteamLibrary"
    elif [[ -d "${games_dir}/GameLibrary/Steam/steamapps" ]]; then
        printf '%s\n' "${games_dir}/GameLibrary/Steam"
    else
        printf '%s\n' "${games_dir}/GameLibrary/Steam"
    fi
}

steam_headless_steam_bin() {
    if [[ -n "${STEAM_BIN:-}" ]]; then
        printf '%s\n' "${STEAM_BIN}"
    elif command -v steam >/dev/null 2>&1; then
        command -v steam
    elif [[ -x /usr/bin/steam ]]; then
        printf '%s\n' /usr/bin/steam
    elif [[ -x /usr/games/steam ]]; then
        printf '%s\n' /usr/games/steam
    else
        printf '%s\n' steam
    fi
}

steam_headless_target_uid() {
    printf '%s\n' "${PUID:-$(id -u "$(steam_headless_user_name)" 2>/dev/null || printf 99)}"
}

steam_headless_target_gid() {
    printf '%s\n' "${PGID:-$(id -g "$(steam_headless_user_name)" 2>/dev/null || printf 100)}"
}

steam_headless_repair_path() {
    local path="$1" mode="${2:-0755}" uid gid
    uid="$(steam_headless_target_uid)"
    gid="$(steam_headless_target_gid)"

    install -d -o "${uid}" -g "${gid}" -m "${mode}" -- "${path}"
}

steam_headless_repair_file_if_exists() {
    local path="$1" mode="${2:-0664}" uid gid
    uid="$(steam_headless_target_uid)"
    gid="$(steam_headless_target_gid)"

    if [[ -e "${path}" && ! -L "${path}" ]]; then
        chown "${uid}:${gid}" -- "${path}" 2>/dev/null || true
        chmod "${mode}" -- "${path}" 2>/dev/null || true
    fi
}

steam_headless_assert_writable_as_user() {
    local path="$1" user_name owner mode
    user_name="$(steam_headless_user_name)"

    if runuser -u "${user_name}" -- test -w "${path}"; then
        return 0
    fi

    owner="$(stat -c '%u:%g' -- "${path}" 2>/dev/null || printf unknown)"
    mode="$(stat -c '%A' -- "${path}" 2>/dev/null || printf unknown)"
    echo "ERROR: ${path} is not writable by ${user_name} ($(steam_headless_target_uid):$(steam_headless_target_gid)); owner=${owner} mode=${mode}" >&2
    return 1
}
