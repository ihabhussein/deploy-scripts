#!/bin/sh

name=$(printf '%s' "$1" | tr -dc '[[:alnum:]_]' | tr '[[:upper:]]' '[[:lower:]]')
dest=/usr/local
root=$dest/www

[ -n "$name" ] || exit 1

oldpwd="$(pwd)"
cd "$(cd $(dirname -- $0); pwd)"

if [ -f "$1/requirements.txt" -a -x "$1/manage.py" ]; then
    type=django
elif [ -f "$1/cpanfile" ]; then
    type=plack
elif [ -f "$1/Gemfile.lock" ]; then
    type=rails
elif [ -f "$1/package.json" ]; then
    type=node
fi

for f in \
    etc/rc.d/__NAME__-$type \
    etc/nginx/conf.d/__NAME__.conf \
; do
    g=$(echo "$dest/$f" | sed -E "s/__NAME__/$name/g")
    /usr/bin/sed \
        -e "s|__NAME__|$name|g;" \
        -e "s|__PDIR__|$root/$name|g;" \
        -e "s|__SOCKET__|/tmp/$name.webapp|g;" \
        < "$f" > "$g"
done

cd $oldpwd
