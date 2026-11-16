#!/usr/bin/env bash
# Dev Stats' helper: finds the accounts your own CLIs are logged in to, and fetches one account's
# contribution calendar.
#
#   dev-stats.sh accounts                      -> [{"provider","host","user"}]
#   dev-stats.sh fetch <provider> <host> <user> -> {"provider","host","user","days":{"YYYY-MM-DD":n}}
#
# No token is read, printed or forwarded: accounts are read from what `gh` and `glab` say they are
# logged in to, and each fetch runs the platform's own CLI (or its public API), which holds its own
# credentials. A failure is a word on stderr and exit 1; stdout is JSON or empty.
set -euo pipefail
export LC_ALL=C NO_COLOR=1 GH_PROMPT_DISABLED=1 NO_PROMPT=1 GIT_TERMINAL_PROMPT=0

fail() {
    printf '%s\n' "$1" >&2
    exit 1
}

valid_host() { [[ ${1:-} =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?(:[0-9]{1,5})?$ ]]; }
valid_user() { [[ ${1:-} =~ ^[A-Za-z0-9_][A-Za-z0-9_.@-]*$ ]] && ((${#1} <= 64)); }

emit() { jq -cn --arg p "$1" --arg h "$2" --arg u "$3" '{provider: $p, host: $h, user: $u}'; }

# ------------------------------------------------------------------ discovery
# `gh auth status` names every host it holds and the account on it; the token it prints is masked,
# and nothing here reads that line.
list_github() {
    command -v gh >/dev/null 2>&1 || return 0
    local host user
    while read -r host user; do
        valid_host "$host" && valid_user "$user" && emit github "$host" "$user"
    done < <(timeout 15 gh auth status 2>&1 </dev/null | sed -n 's/.*[Ll]ogged in to \([^ ]*\) account \([^ ]*\).*/\1 \2/p' || true)
}

# `glab auth status` says "Logged in to gitlab.com as someone".
list_gitlab() {
    command -v glab >/dev/null 2>&1 || return 0
    local host user
    while read -r host user; do
        valid_host "$host" && valid_user "$user" && emit gitlab "$host" "$user"
    done < <(timeout 15 glab auth status 2>&1 </dev/null | sed -n 's/.*[Ll]ogged in to \([^ ]*\) as \([^ ]*\).*/\1 \2/p' || true)
}

# tea (Gitea's CLI) lists its logins as JSON; an older tea prints a table nobody can parse, so it
# names nothing and the person types the account instead.
list_tea() {
    command -v tea >/dev/null 2>&1 || return 0
    local url user host
    while IFS=$'\t' read -r url user; do
        host=${url#*://}
        host=${host%%/*}
        valid_host "$host" && valid_user "$user" && emit forgejo "$host" "$user"
    done < <(timeout 15 tea login list --output json 2>/dev/null </dev/null |
        jq -r '.[]? | [(.url // ""), (.user // "")] | @tsv' 2>/dev/null || true)
}

cmd_accounts() {
    { list_github; list_gitlab; list_tea; } 2>/dev/null |
        jq -cs 'reduce .[] as $a ([]; if any(.[]; . == $a) then . else . + [$a] end)'
}

# ---------------------------------------------------------------------- fetch
# Each fetch prints {date: count} for the last year; quiet days are left out and read as 0.

fetch_github() { # host user
    timeout 40 gh api graphql --hostname "$1" -f login="$2" \
        -f query='query($login:String!){user(login:$login){contributionsCollection{contributionCalendar{weeks{contributionDays{date contributionCount}}}}}}' \
        2>/dev/null </dev/null |
        jq -c '.data.user.contributionsCollection.contributionCalendar.weeks
            | map(.contributionDays) | add // []
            | map({key: .date, value: .contributionCount}) | from_entries
            | with_entries(select(.value != 0))'
}

fetch_gitlab() { # host user
    local id from
    id=$(timeout 20 glab api --hostname "$1" "users?username=$2" 2>/dev/null </dev/null |
        jq -r '.[0].id // empty' 2>/dev/null) || return 1
    [[ $id =~ ^[0-9]+$ ]] || return 1
    from=$(date -d '366 days ago' +%F)
    timeout 60 glab api --hostname "$1" --paginate "users/$id/events?after=$from&per_page=100" 2>/dev/null </dev/null |
        jq -cs 'add // [] | map(select(.created_at != null) | .created_at[0:10])
            | group_by(.) | map({key: .[0], value: length}) | from_entries'
}

# Forgejo, Gitea and Codeberg publish the heatmap of a public account.
fetch_forgejo() { # host user
    timeout 30 curl -fsS --proto '=https' --max-time 25 "https://$1/api/v1/users/$2/heatmap" 2>/dev/null </dev/null |
        jq -c 'map({key: (.timestamp | strftime("%Y-%m-%d")), value: (.contributions // 0)}) | from_entries
            | with_entries(select(.value != 0))'
}

cmd_fetch() { # provider host user
    local provider=${1:-} host=${2:-} user=${3:-} days
    [[ $provider =~ ^(github|gitlab|forgejo)$ ]] && valid_host "$host" && valid_user "$user" || fail bad-account
    case $provider in
        github) command -v gh >/dev/null 2>&1 || fail no-cli ;;
        gitlab) command -v glab >/dev/null 2>&1 || fail no-cli ;;
        forgejo) command -v curl >/dev/null 2>&1 || fail no-cli ;;
    esac
    if ! days=$("fetch_$provider" "$host" "$user"); then
        fail request-failed
    fi
    [[ -n $days ]] || fail request-failed
    printf '%s' "$days" | jq -e 'type == "object"' >/dev/null 2>&1 || fail request-failed
    jq -cn --arg p "$provider" --arg h "$host" --arg u "$user" --argjson d "$days" \
        '{provider: $p, host: $h, user: $u, days: $d}'
}

case ${1:-} in
    accounts)
        command -v jq >/dev/null 2>&1 || fail no-jq
        cmd_accounts
        ;;
    fetch)
        shift
        command -v jq >/dev/null 2>&1 || fail no-jq
        cmd_fetch "${1:-}" "${2:-}" "${3:-}"
        ;;
    *)
        fail bad-command
        ;;
esac
