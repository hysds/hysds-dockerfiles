#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Enter release date as arg: $0 <yyyymmdd> <git_oauth_token>"
  echo "e.g.: $0 20170620 my_git_oauth_token"
  exit 1
fi
REL_DATE=$1
GIT_OAUTH_TOKEN=$2

# get uid and gid
ID=$(id -u)
GID=$(id -g)

echo "REL_DATE is $REL_DATE"
echo "ID is $ID"
echo "GID is $GID"

# build hysds/pge-isce_giant
echo "#############################"
echo "Building hysds/pge-isce_giant"
echo "#############################"
docker build --rm --force-rm -t hysds/pge-isce_giant:${REL_DATE} -f Dockerfile.hysds-pge-isce-giant --build-arg git_oauth_token=${GIT_OAUTH_TOKEN} /home/ops
docker tag hysds/pge-isce_giant:${REL_DATE} hysds/pge-isce_giant:latest || exit 1

# export hysds/pge-isce_giant
cd /data/docker_images/
docker save hysds/pge-isce_giant:${REL_DATE} > hysds-pge-isce_giant-${REL_DATE}.tar
echo "done saving"
pigz -f hysds-pge-isce_giant-${REL_DATE}.tar
docker save hysds/pge-isce_giant:latest > hysds-pge-isce_giant-latest.tar
echo "done saving"
pigz -f hysds-pge-isce_giant-latest.tar
cd -

# build aria/isce_giant
echo "#############################"
echo "Building aria/isce_giant"
echo "#############################"
docker build --rm --force-rm -t aria/isce_giant:${REL_DATE} -f Dockerfile.isce-giant --build-arg git_oauth_token=${GIT_OAUTH_TOKEN} /home/ops || exit 1
docker tag aria/isce_giant:${REL_DATE} aria/isce_giant:latest || exit 1

# export aria/isce_giant
cd /data/docker_images/
docker save aria/isce_giant:${REL_DATE} > aria-isce_giant-${REL_DATE}.tar
echo "done saving"
pigz -f aria-isce_giant-${REL_DATE}.tar
docker save aria/isce_giant:latest > aria-isce_giant-latest.tar
echo "done saving"
pigz -f aria-isce_giant-latest.tar
