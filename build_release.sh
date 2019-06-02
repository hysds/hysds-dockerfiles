#!/bin/bash
# usage: ./build_release.sh v3.0.0-rc.0 hysds master

BASE_PATH=$(dirname "${BASH_SOURCE}")
BASE_PATH=$(cd "${BASE_PATH}"; pwd)

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <framework-release> <org> <branch>"
  echo "e.g.: $0 v3.0.0-rc.0 hysds master"
  exit 1
fi
RELEASE=$1
ORG=$2
BRANCH=$3

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
docker tag hysds/base:${RELEASE} hysds/base:latest || exit 1
docker tag hysds/cuda-base:${RELEASE} hysds/cuda-base:latest || exit 1
docker push hysds/base:${RELEASE} || exit 1
docker push hysds/cuda-base:${RELEASE} || exit 1
docker push hysds/base:latest || exit 1
docker push hysds/cuda-base:latest || exit 1
cd ..
rm -rf hysds_base

# build hysds/dev
echo "#############################"
echo "Building hysds/dev"
echo "#############################"
git clone --single-branch -b ${BRANCH} https://github.com/${ORG}/puppet-hysds_dev.git hysds_dev
cd hysds_dev
./build_docker.sh ${RELEASE} ${ORG} ${BRANCH} || exit 1
docker tag hysds/dev:${RELEASE} hysds/dev:latest || exit 1
docker tag hysds/cuda-dev:${RELEASE} hysds/cuda-dev:latest || exit 1
docker push hysds/dev:${RELEASE} || exit 1
docker push hysds/cuda-dev:${RELEASE} || exit 1
docker push hysds/dev:latest || exit 1
docker push hysds/cuda-dev:latest || exit 1
cd ..
rm -rf hysds_dev
cd $BASE_PATH

# hysds/redis
echo "#############################"
echo "Building hysds/redis"
echo "#############################"
docker build --rm --force-rm -t hysds/redis:${RELEASE} -f Dockerfile.hysds-redis . || exit 1
docker tag hysds/redis:${RELEASE} hysds/redis:latest || exit 1
docker push hysds/redis:${RELEASE} || exit 1
docker push hysds/redis:latest || exit 1

# hysds/elasticsearch
echo "#############################"
echo "Building hysds/elasticsearch"
echo "#############################"
docker build --rm --force-rm -t hysds/elasticsearch:1.7 -f Dockerfile.hysds-elasticsearch . || exit 1
docker tag hysds/elasticsearch:1.7 hysds/elasticsearch:latest || exit 1
docker push hysds/elasticsearch:1.7 || exit 1
docker push hysds/elasticsearch:latest || exit 1

# hysds/rabbitmq
echo "#############################"
echo "Building hysds/rabbitmq"
echo "#############################"
docker build --rm --force-rm -t hysds/rabbitmq:3-management -f Dockerfile.hysds-rabbitmq . || exit 1
docker tag hysds/rabbitmq:3-management hysds/rabbitmq:latest || exit 1
docker push hysds/rabbitmq:3-management || exit 1
docker push hysds/rabbitmq:latest || exit 1

# build worker hysds components
echo "#######################################"
echo "Building hysds/pge-base and hysds/verdi"
echo "#######################################"
cd $TMP_DIR
git clone -b docker --single-branch https://github.com/${ORG}/puppet-verdi.git verdi
cd verdi
./build_docker.sh ${RELEASE} || exit 1
cd ..
rm -rf verdi
cd $BASE_PATH
for i in verdi pge-base; do
  docker tag hysds/${i}:${RELEASE} hysds/${i}:latest || exit 1
  docker push hysds/${i}:${RELEASE} || exit 1
  docker push hysds/${i}:latest || exit 1
  if [ "$i" = "pge-base" ]; then
    docker tag hysds/cuda-${i}:${RELEASE} hysds/cuda-${i}:latest || exit 1
    docker push hysds/cuda-${i}:${RELEASE} || exit 1
    docker push hysds/cuda-${i}:latest || exit 1
  fi
done

# export verdi
cd $IMG_DIR
docker save hysds/verdi:${RELEASE} > hysds-verdi-${RELEASE}.tar; echo "done saving"; pigz -f hysds-verdi-${RELEASE}.tar
docker save hysds/verdi:latest > hysds-verdi-latest.tar; echo "done saving"; pigz -f hysds-verdi-latest.tar
cd -

# build hysds components
for i in mozart metrics grq cont_int; do
  echo "#############################"
  echo "Building hysds/$i"
  echo "#############################"
  cd $TMP_DIR
  git clone -b docker --single-branch https://github.com/${ORG}/puppet-${i} ${i}
  cd ${i}
  ./build_docker.sh ${RELEASE} || exit 1
  cd ..
  rm -rf ${i}
  cd $BASE_PATH
  docker tag hysds/${i}:${RELEASE} hysds/${i}:latest || exit 1
  docker push hysds/${i}:${RELEASE} || exit 1
  docker push hysds/${i}:latest || exit 1
done

# clean temp dir
rm -rf $TMP_DIR
