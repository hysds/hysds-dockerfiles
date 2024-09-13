#!/bin/bash
set -e

# set HOME explicitly
export HOME=/root

# wait for redis and ES
/wait-for-it.sh -t 30 grq-redis:6379
/wait-for-it.sh -t 30 grq-elasticsearch:9200

# get group id
GID=$(id -g)

# update user and group ids
gosu 0:0 groupmod -g $GID ops 2>/dev/null
gosu 0:0 usermod -u $UID -g $GID ops 2>/dev/null
gosu 0:0 usermod -aG docker ops 2>/dev/null

# update ownership
gosu 0:0 chown -R $UID:$GID $HOME 2>/dev/null || true
gosu 0:0 chown -R $UID:$GID /var/run/docker.sock 2>/dev/null || true
gosu 0:0 chown -R $UID:$GID /var/log/supervisor 2>/dev/null || true

# source bash profile
source $HOME/.bash_profile

# source grq virtualenv
if [ -e "$HOME/sciflo/bin/activate" ]; then
  source $HOME/sciflo/bin/activate
fi

# install ES template
$HOME/sciflo/ops/grq2/scripts/install_es_template.sh || :

if [[ "$#" -eq 1  && "$@" == "supervisord" ]]; then
  set -- supervisord -n
else
  if [ "${1:0:1}" = '-' ]; then
    set -- supervisord "$@"
  fi
fi

exec gosu $UID:$GID "$@"
