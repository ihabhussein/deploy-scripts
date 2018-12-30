#!/bin/sh

dest=/usr/local
install='install -bpSv'

oldpwd="$(pwd)"
cd "$(cd $(dirname -- $0); pwd)"

find bin                     -type f | xargs -I XX  $install         XX $dest/XX

find etc                     -type d | xargs -I XX  mkdir -p            $dest/XX
find etc/periodic            -type f | xargs -I XX  $install         XX $dest/XX
find etc/syslog.d            -type f | xargs -I XX  $install -m 0644 XX $dest/XX
find etc/newsyslog.conf.d    -type f | xargs -I XX  $install -m 0644 XX $dest/XX
find etc/postgresql.conf.d   -type f | xargs -I XX  $install -m 0644 XX $dest/XX

cd $oldpwd
