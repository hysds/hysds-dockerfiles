#!/bin/bash
set -e

# set HOME explicitly
export HOME=/root

# wait for rabbitmq, redis, and ES
/wait-for-it.sh -t 30 ${RABBITMQ_HOST:-mozart-rabbitmq}:${RABBITMQ_PORT:-15672}
/wait-for-it.sh -t 30 ${REDIS_HOST:-mozart-redis}:${REDIS_PORT:-6379}
/wait-for-it.sh -t 30 ${ES_HOST:-mozart-elasticsearch}:${ES_PORT:-9200}


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

# source mozart virtualenv
if [ -e "$HOME/mozart/bin/activate" ]; then
  source $HOME/mozart/bin/activate
fi

# ensure db for mozart_job_management exists
if [ ! -d "$HOME/mozart/ops/mozart/data" ]; then
  mkdir -p $HOME/mozart/ops/mozart/data
fi
if [ -e `readlink $HOME/mozart/ops/mozart/settings.cfg` ]; then
  $HOME/mozart/ops/mozart/db_create.py
fi

# create user rules index
$HOME/mozart/ops/mozart/scripts/create_user_rules_index.py || :

if [[ "$#" -eq 1  && "$@" == "supervisord" ]]; then
  set -- supervisord -n
else
  if [ "${1:0:1}" = '-' ]; then
    set -- supervisord "$@"
  fi
fi

exec gosu $UID:$GID "$@"
