#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

set -e

if [[ "$#" -eq 1  && "$@" == "redis-server" ]]; then
  set -- redis-server /usr/local/etc/redis.conf
else
  if [ "${1:0:1}" = '-' ]; then
    set -- redis-server "$@"
  fi
fi

exec "$@"
