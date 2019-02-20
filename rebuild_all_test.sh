#!/bin/bash
BASE_PATH=$(dirname "${BASH_SOURCE}")
BASE_PATH=$(cd "${BASE_PATH}"; pwd)

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <yyyymmdd> <org> <branch>"
  echo "e.g.: $0 20170620 hysds master"
  exit 1
fi
REL_DATE=$1
ORG=$2
BRANCH=$3

# get uid and gid
ID=$(id -u)
GID=$(id -g)

echo "REL_DATE is $REL_DATE"
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
./build_docker.sh ${REL_DATE}-${BRANCH} ${ORG} ${BRANCH} || exit 1
docker tag hysds/base:${REL_DATE}-${BRANCH} hysds/base:${BRANCH} || exit 1
docker tag hysds/cuda-base:${REL_DATE}-${BRANCH} hysds/cuda-base:${BRANCH} || exit 1
docker push hysds/base:${REL_DATE}-${BRANCH} || exit 1
docker push hysds/cuda-base:${REL_DATE}-${BRANCH} || exit 1
docker push hysds/base:${BRANCH} || exit 1
docker push hysds/cuda-base:${BRANCH} || exit 1
cd ..
rm -rf hysds_base

# build hysds/dev
echo "#############################"
echo "Building hysds/dev"
echo "#############################"
git clone --single-branch -b ${BRANCH} https://github.com/${ORG}/puppet-hysds_dev.git hysds_dev
cd hysds_dev
./build_docker.sh ${REL_DATE}-${BRANCH} ${ORG} ${BRANCH} || exit 1
docker tag hysds/dev:${REL_DATE}-${BRANCH} hysds/dev:${BRANCH} || exit 1
docker tag hysds/cuda-dev:${REL_DATE}-${BRANCH} hysds/cuda-dev:${BRANCH} || exit 1
docker push hysds/dev:${REL_DATE}-${BRANCH} || exit 1
docker push hysds/cuda-dev:${REL_DATE}-${BRANCH} || exit 1
docker push hysds/dev:${BRANCH} || exit 1
docker push hysds/cuda-dev:${BRANCH} || exit 1
cd ..
rm -rf hysds_dev
cd $BASE_PATH

# hysds/redis
echo "#############################"
echo "Building hysds/redis"
echo "#############################"
docker build --rm --force-rm -t hysds/redis:${REL_DATE}-${BRANCH} -f Dockerfile.hysds-redis . || exit 1
docker tag hysds/redis:${REL_DATE}-${BRANCH} hysds/redis:${BRANCH} || exit 1
docker push hysds/redis:${REL_DATE}-${BRANCH} || exit 1
docker push hysds/redis:${BRANCH} || exit 1

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
git clone -b docker-python3 --single-branch https://github.com/hysds/puppet-verdi.git verdi
cd verdi
./build_docker.sh ${REL_DATE}-${BRANCH} || exit 1
cd ..
rm -rf verdi
cd $BASE_PATH
for i in verdi pge-base; do
  docker tag hysds/${i}:${REL_DATE}-${BRANCH} hysds/${i}:python3 || exit 1
  docker push hysds/${i}:${REL_DATE}-${BRANCH} || exit 1
  docker push hysds/${i}:python3 || exit 1
  if [ "$i" = "pge-base" ]; then
    docker tag hysds/cuda-${i}:${REL_DATE}-${BRANCH} hysds/cuda-${i}:python3 || exit 1
    docker push hysds/cuda-${i}:${REL_DATE}-${BRANCH} || exit 1
    docker push hysds/cuda-${i}:python3 || exit 1
  fi
done

# export verdi
cd $IMG_DIR
#docker save hysds/verdi:${REL_DATE} > hysds-verdi-${REL_DATE}.tar; echo "done saving"; pigz -f hysds-verdi-${REL_DATE}.tar
docker save hysds/verdi:python3 > hysds-verdi-python3.tar; echo "done saving"; pigz -f hysds-verdi-python3.tar
cd -

# build hysds components
for i in mozart metrics grq cont_int; do
  echo "#############################"
  echo "Building hysds/$i"
  echo "#############################"
  cd $TMP_DIR
  git clone -b docker-python3 --single-branch https://github.com/hysds/puppet-${i} ${i}
  cd ${i}
  ./build_docker.sh ${REL_DATE}-${BRANCH} || exit 1
  cd ..
  rm -rf ${i}
  cd $BASE_PATH
  docker tag hysds/${i}:${REL_DATE}-${BRANCH} hysds/${i}:python3 || exit 1
  docker push hysds/${i}:${REL_DATE}-${BRANCH} || exit 1
  docker push hysds/${i}:python3 || exit 1
done

# clean temp dir
rm -rf $TMP_DIR
