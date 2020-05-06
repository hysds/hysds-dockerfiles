#!/bin/bash
# usage: ./build_develop.sh hysds

BASE_PATH=$(dirname "${BASH_SOURCE}")
BASE_PATH=$(cd "${BASE_PATH}"; pwd)

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <org> <branch>"
  echo "e.g.: $0 hysds develop"
  exit 1
fi
ORG=$1
BRANCH=$2
RELEASE=$BRANCH

# get puppet repo branch for docker builds
PUPPET_DOCKER_BRANCH="docker"

# get uid and gid
ID=$(id -u)
GID=$(id -g)

echo "RELEASE is $RELEASE"
echo "ID is $ID"
echo "GID is $GID"

# pull latest docker.io centos, rabbitmq and elasticsearch
docker pull docker.io/centos:7 || exit 1
docker tag docker.io/centos:7 docker.io/centos:latest || exit 1

# make temp workspace
TMP_DIR=$BASE_PATH/.tmp
rm -rf $TMP_DIR
mkdir $TMP_DIR
cd $TMP_DIR

# create artifacts directory
IMG_DIR=${BASE_PATH}/images
mkdir -p $IMG_DIR

# build hysds/base
echo "#############################"
echo "Building hysds/base"
echo "#############################"
git clone --single-branch -b ${BRANCH} https://github.com/${ORG}/puppet-hysds_base.git hysds_base
cd hysds_base
./build_docker.sh ${RELEASE} ${ORG} ${BRANCH} || exit 1
cd ..
rm -rf hysds_base

# build hysds/dev
echo "#############################"
echo "Building hysds/dev"
echo "#############################"
git clone --single-branch -b ${BRANCH} https://github.com/${ORG}/puppet-hysds_dev.git hysds_dev
cd hysds_dev
./build_docker.sh ${RELEASE} ${ORG} ${BRANCH} || exit 1
cd ..
rm -rf hysds_dev
cd $BASE_PATH

# build worker hysds components
echo "#######################################"
echo "Building hysds/pge-base and hysds/verdi"
echo "#######################################"
cd $TMP_DIR
git clone -b ${PUPPET_DOCKER_BRANCH} --single-branch https://github.com/${ORG}/puppet-verdi.git verdi
cd verdi
./build_docker.sh ${RELEASE} || exit 1
cd ..
rm -rf verdi
cd $BASE_PATH

# export verdi and docker registry
cd $IMG_DIR
docker save hysds/verdi:${RELEASE} > hysds-verdi-${RELEASE}.tar; echo "done saving"; pigz -f hysds-verdi-${RELEASE}.tar
exit
docker pull registry:2
docker save registry:2 > docker-registry-2.tar; echo "done saving"; pigz -f docker-registry-2.tar
cd -

# clean temp dir
rm -rf $TMP_DIR
