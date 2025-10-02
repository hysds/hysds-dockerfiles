#!/bin/bash
set -e

# set HOME explicitly
export HOME=/root

# wait for redis and ES
/wait-for-it.sh -t 30 ${REDIS_HOST:-metrics-redis}:${REDIS_PORT:-6379}
/wait-for-it.sh -t 30 ${ES_HOST:-metrics-elasticsearch}:${ES_PORT:-9200}


# get group id
GID=$(id -g)

# update user and group ids
gosu 0:0 groupmod -g $GID ops 2>/dev/null
gosu 0:0 usermod -u $UID -g $GID ops 2>/dev/null
gosu 0:0 usermod -aG docker ops 2>/dev/null

# create metrics symlink
gosu 0:0 ln -sf $HOME/mozart $HOME/metrics || true

# update ownership
gosu 0:0 chown -R $UID:$GID $HOME 2>/dev/null || true
gosu 0:0 chown -R $UID:$GID /var/run/docker.sock 2>/dev/null || true
gosu 0:0 chown -R $UID:$GID /var/log/supervisor 2>/dev/null || true

# source bash profile
source $HOME/.bash_profile

# source metrics virtualenv (under mozart)
if [ -e "$HOME/mozart/bin/activate" ]; then
  source $HOME/mozart/bin/activate
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
