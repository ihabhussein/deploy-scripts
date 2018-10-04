#!/bin/sh

: ${user=git}
: ${group=git}
: ${home=/home/git}

: ${git=/usr/local/bin/git}
: ${git_shell=/usr/local/bin/git-shell}
: ${psql=/usr/local/bin/psql -U postgres}
: ${git_hooks=/usr/local/bin/git-hooks}

set -e

sysinit() {
    if [ $# -ne 0 ]; then
        echo "Usage: system_init" >&2
        return 1
    fi

    getent group $group || \
        pw groupadd $group
    getent passwd $user || \
        pw useradd $user -c '& Server' -d $home -g $group -w no -s $git_shell

    mkdir -p $home/.ssh $home/.keys
    touch $home/.ssh/authorized_keys

    chown -R $user:$group $home
    chmod 700 $home $home/.ssh $home/.keys
    chmod 600 $home/.ssh/authorized_keys
}

_update_authorized_keys() {
    new_file=$(mktemp)
    for k in $home/.keys/*; do
        [ -f "$k" ] && printf 'environment="GIT__USER=%s" %s' \
            $(basename -- "$k") $(cat "$k") \
            >> $new_file
    done
    mv $new_file $home/.ssh/authorized_keys

    chown $user:$group $home/.ssh/authorized_keys
    chmod 600 $home/.ssh/authorized_keys
}

add_key() {
    if [ $# -ne 2 -o ! -f "$2" ]; then
        echo "Usage: add_key user_name key_file_name" >&2
        return 1
    fi

    cp "$2" "$home/.keys/$1"
    _update_authorized_keys
}

remove_key() {
    if [ $# -ne 1 ]; then
        echo "Usage: remove_key user_name" >&2
        return 1
    fi

    rm "$home/.keys/$1"
    _update_authorized_keys
}

_create_database() {
    local username=$(openssl rand -base64 64 | tr -cd 'a-z'       | head -c 12)
    local password=$(openssl rand -base64 64 | tr -cd '0-9A-Za-z' | head -c 12)
    local database=$(openssl rand -base64 64 | tr -cd 'a-z'       | head -c 12)

    $psql -c "CREATE USER $username WITH PASSWORD '$password';" 2>&1 >/dev/null
    $psql -c "CREATE DATABASE $database WITH OWNER $username;"  2>&1 >/dev/null

    printf "export DATABASE_URL=postgresql://%s:%s@%s:%s/%s" \
        $username $password ${PGHOST-localhost} ${PGPORT-5432} $database
}

init() {
    if [ $# -lt 1 -o $# -gt 4 ]; then
        echo "Usage: init repo [target [service [ref]]]" >&2
        return 1
    fi

    $git init --bare $home/$1
    GIT_DIR=$home/$1; export GIT_DIR
    $git config core.hooksPath $git_hooks

    if [ -n "$2" ]; then
        $git config deploy.target  $2
        $git config deploy.service ${3-$(basename -- $2)}
        $git config deploy.ref     ${4-master}

        mkdir -p "$2"
        echo "export PYTHONUSERBASE=$2/.local" >> "$2/env.sh"
        echo "export PYTHONPATH=$2/src"        >> "$2/env.sh"
        _create_database                       >> "$2/env.sh"
    fi

    chown -R $user:$group $home/$1
}

"$@"
