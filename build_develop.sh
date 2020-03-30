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
if [ "$BRANCH" = "develop-es7" ]; then
  PUPPET_DOCKER_BRANCH="docker-es7"
fi

# get uid and gid
ID=$(id -u)
GID=$(id -g)

echo "RELEASE is $RELEASE"
echo "ID is $ID"
echo "GID is $GID"

# pull latest docker.io centos, rabbitmq and elasticsearch
docker pull docker.io/elasticsearch:1.7 || exit 1
docker pull docker.io/rabbitmq:3-management || exit 1
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
docker push hysds/base:${RELEASE} || exit 1
docker push hysds/cuda-base:${RELEASE} || exit 1
cd ..
rm -rf hysds_base

# build hysds/dev
echo "#############################"
echo "Building hysds/dev"
echo "#############################"
git clone --single-branch -b ${BRANCH} https://github.com/${ORG}/puppet-hysds_dev.git hysds_dev
cd hysds_dev
./build_docker.sh ${RELEASE} ${ORG} ${BRANCH} || exit 1
docker push hysds/dev:${RELEASE} || exit 1
docker push hysds/cuda-dev:${RELEASE} || exit 1
cd ..
rm -rf hysds_dev
cd $BASE_PATH

# hysds/redis
echo "#############################"
echo "Building hysds/redis"
echo "#############################"
docker build --rm --force-rm -t hysds/redis:${RELEASE} -f Dockerfile.hysds-redis . || exit 1
docker push hysds/redis:${RELEASE} || exit 1

# hysds/elasticsearch
echo "#############################"
echo "Building hysds/elasticsearch"
echo "#############################"
docker build --rm --force-rm -t hysds/elasticsearch:${RELEASE} -f Dockerfile.hysds-elasticsearch . || exit 1
docker push hysds/elasticsearch:${RELEASE} || exit 1

# hysds/rabbitmq
echo "#############################"
echo "Building hysds/rabbitmq"
echo "#############################"
docker build --rm --force-rm -t hysds/rabbitmq:${RELEASE} -f Dockerfile.hysds-rabbitmq . || exit 1
docker push hysds/rabbitmq:${RELEASE} || exit 1

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
for i in verdi pge-base; do
  docker push hysds/${i}:${RELEASE} || exit 1
  if [ "$i" = "pge-base" ]; then
    docker push hysds/cuda-${i}:${RELEASE} || exit 1
  fi
done

# export verdi and docker registry
cd $IMG_DIR
docker save hysds/verdi:${RELEASE} > hysds-verdi-${RELEASE}.tar; echo "done saving"; pigz -f hysds-verdi-${RELEASE}.tar
docker pull registry:2
docker save registry:2 > docker-registry-2.tar; echo "done saving"; pigz -f docker-registry-2.tar
cd -

# build hysds components
for i in mozart metrics grq cont_int; do
  echo "#############################"
  echo "Building hysds/$i"
  echo "#############################"
  cd $TMP_DIR
  git clone -b ${PUPPET_DOCKER_BRANCH} --single-branch https://github.com/${ORG}/puppet-${i} ${i}
  cd ${i}
  ./build_docker.sh ${RELEASE} || exit 1
  cd ..
  rm -rf ${i}
  cd $BASE_PATH
  docker push hysds/${i}:${RELEASE} || exit 1
done

# clean temp dir
rm -rf $TMP_DIR
