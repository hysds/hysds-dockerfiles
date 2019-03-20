#!/bin/bash

VERDI_DIR=/home/ops/verdi
WORK_DIR=/data/work


# create virtualenv if not found
if [ ! -e "$VERDI_DIR/bin/activate" ]; then
  virtualenv --system-site-packages $VERDI_DIR
  echo "Created virtualenv at $VERDI_DIR."
fi


# source virtualenv
source $VERDI_DIR/bin/activate


# install latest pip and setuptools
pip install -U pip
pip install -U setuptools


# force install supervisor
if [ ! -e "$VERDI_DIR/bin/supervisord" ]; then
  pip install --ignore-installed supervisor
fi


# extract beefed autoindex
if [ ! -d "$WORK_DIR/.index-style" ]; then
  cd $WORK_DIR
  tar xvfj $VERDI_DIR/src/beefed-autoindex-open_in_new_win.tbz2
fi


# create etc directory
if [ ! -d "$VERDI_DIR/etc" ]; then
  mkdir $VERDI_DIR/etc
fi


# create log directory
if [ ! -d "$VERDI_DIR/log" ]; then
  mkdir $VERDI_DIR/log
fi


# create run directory
if [ ! -d "$VERDI_DIR/run" ]; then
  mkdir $VERDI_DIR/run
fi


# set oauth token
OAUTH_CFG="$HOME/.git_oauth_token"
if [ -e "$OAUTH_CFG" ]; then
  source $OAUTH_CFG
  GIT_URL="https://${GIT_OAUTH_TOKEN}@github.com"
else
  GIT_URL="https://github.com"
fi


# create ops directory
OPS="$VERDI_DIR/ops"
if [ ! -d "$OPS" ]; then
  mkdir $OPS
fi


# export latest prov_es package
cd $OPS
PACKAGE=prov_es
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest osaka package
cd $OPS
GITHUB_REPO=osaka
PACKAGE=osaka
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${GITHUB_REPO}.git $PACKAGE
fi
cd $OPS/$PACKAGE
pip install -U pyasn1
pip install -U pyasn1-modules
pip install -U six
#pip install -U python-dateutil
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest hysds_commons package
cd $OPS
PACKAGE=hysds_commons
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest hysds package
cd $OPS
PACKAGE=hysds
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE/third_party/celery-v4.2.1
pip install -e .
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi


# export latest sciflo package
cd $OPS
PACKAGE=sciflo
if [ ! -d "$OPS/$PACKAGE" ]; then
  git clone ${GIT_URL}/hysds/${PACKAGE}.git
fi
cd $OPS/$PACKAGE
pip install -e .
if [ "$?" -ne 0 ]; then
  echo "Failed to run 'pip install -e .' for $PACKAGE."
  exit 1
fi
