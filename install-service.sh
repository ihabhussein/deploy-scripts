#!/bin/sh

name=$(printf '%s' "$1" | tr -dc '[[:alnum:]_]' | tr '[[:upper:]]' '[[:lower:]]')
dest=/usr/local
root=$dest/www

[ -n "$name" ] || exit 1

oldpwd="$(pwd)"
cd "$(cd $(dirname -- $0); pwd)"

for f in \
    etc/rc.d/__NAME__ \
    etc/monit.d/__NAME__ \
    etc/nginx/conf.d/__NAME__.conf \
; do
    g=$(echo "$dest/$f" | sed -E "s/__NAME__/$name/g")
    /usr/bin/sed \
        -e "s|__NAME__|$name|g;" \
        -e "s|__PDIR__|$root/$name|g;" \
        -e "s|__SOCKET__|/tmp/gunicorn.$name|g;" \
        < "$f" > "$g"
done

cd $oldpwd
