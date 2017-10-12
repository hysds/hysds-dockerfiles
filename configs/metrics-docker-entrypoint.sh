#!/bin/bash
set -e

# wait for redis and ES
/wait-for-it.sh -t 30 metrics-redis:6379
/wait-for-it.sh -t 30 metrics-elasticsearch:9200

# get group id
GID=$(id -g)

# update user and group ids
gosu 0:0 groupmod -g $GID ops 2>/dev/null
gosu 0:0 usermod -u $UID -g $GID ops 2>/dev/null
gosu 0:0 usermod -aG docker ops 2>/dev/null

# create metrics symlink
gosu 0:0 ln -sf /home/ops/mozart /home/ops/metrics || true

# update ownership
gosu 0:0 chown -R $UID:$GID /home/ops 2>/dev/null || true
gosu 0:0 chown -R $UID:$GID /var/run/docker.sock 2>/dev/null || true
gosu 0:0 chown -R $UID:$GID /var/log/supervisor 2>/dev/null || true

# source metrics virtualenv (under mozart)
if [ -e "/home/ops/mozart/bin/activate" ]; then
  source /home/ops/mozart/bin/activate
fi

# install kibana metrics
if [ -e "/tmp/install_kibana_metrics.py" ]; then
  /tmp/install_kibana_metrics.py
fi

if [[ "$#" -eq 1  && "$@" == "supervisord" ]]; then
  set -- supervisord -n
else
  if [ "${1:0:1}" = '-' ]; then
    set -- supervisord "$@"
  fi
fi

exec gosu $UID:$GID "$@"
