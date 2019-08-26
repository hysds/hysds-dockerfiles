#!/bin/bash
set -e

# set HOME explicitly
export HOME=/home/ops

# get group id
GID=$(id -g)

# update user and group ids
gosu 0:0 groupmod -g $GID ops 2>/dev/null
gosu 0:0 usermod -u $UID -g $GID ops 2>/dev/null
gosu 0:0 usermod -aG docker ops 2>/dev/null

# update ownership
gosu 0:0 chown -R $UID:$GID $HOME 2>/dev/null || true
gosu 0:0 chown -R $UID:$GID /var/run/docker.sock 2>/dev/null || true

# source bash profile
source $HOME/.bash_profile

# start Xvfb
XVFB_WHD=${XVFB_WHD:-1280x720x16}
Xvfb :99 -ac -screen 0 $XVFB_WHD -nolisten tcp &
export DISPLAY=:99

exec gosu $UID:$GID "$@"
