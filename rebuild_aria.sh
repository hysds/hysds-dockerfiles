#!/bin/bash
BASE_PATH=$(dirname "${BASH_SOURCE}")
BASE_PATH=$(cd "${BASE_PATH}"; pwd)

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

# make temp workspace
TMP_DIR=$BASE_PATH/.tmp
rm -rf $TMP_DIR
mkdir $TMP_DIR
cd $TMP_DIR

# build hysds/pge-isce_giant
echo "#############################"
echo "Building hysds/pge-isce_giant"
echo "#############################"
git clone -b docker-lite --single-branch https://${GIT_OAUTH_TOKEN}@github.jpl.nasa.gov/aria-hysds/puppet-isce.git isce
cd isce
./build_docker.sh ${REL_DATE} ${GIT_OAUTH_TOKEN} || exit 1
docker tag hysds/pge-isce_giant:${REL_DATE} hysds/pge-isce_giant:latest || exit 1
docker tag hysds/pge-isce_giant:${REL_DATE} aria/isce_giant:${REL_DATE} || exit 1
docker tag aria/isce_giant:${REL_DATE} aria/isce_giant:latest || exit 1
cd ..
rm -rf isce

# export hysds/pge-isce_giant
cd /data/docker_images/
docker save hysds/pge-isce_giant:${REL_DATE} > hysds-pge-isce_giant-${REL_DATE}.tar
echo "done saving"
pigz -f hysds-pge-isce_giant-${REL_DATE}.tar
docker save hysds/pge-isce_giant:latest > hysds-pge-isce_giant-latest.tar
echo "done saving"
pigz -f hysds-pge-isce_giant-latest.tar

# export aria/isce_giant
docker save aria/isce_giant:${REL_DATE} > aria-isce_giant-${REL_DATE}.tar
echo "done saving"
pigz -f aria-isce_giant-${REL_DATE}.tar
docker save aria/isce_giant:latest > aria-isce_giant-latest.tar
echo "done saving"
pigz -f aria-isce_giant-latest.tar

# clean temp dir
rm -rf $TMP_DIR
