#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Enter release date as arg: $0 <yyyymmdd>"
  echo "e.g.: $0 20170620"
  exit 1
fi
REL_DATE=$1

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

# build hysds/centos
echo "#############################"
echo "Building hysds/centos"
echo "#############################"
docker build --rm --force-rm -t hysds/centos:7_${REL_DATE} -f Dockerfile.hysds-centos7 /home/ops || exit 1
docker tag hysds/centos:7_${REL_DATE} hysds/centos:7 || exit 1
docker tag hysds/centos:7_${REL_DATE} hysds/centos:latest || exit 1
docker push hysds/centos:7_${REL_DATE} || exit 1
docker push hysds/centos:7 || exit 1
docker push hysds/centos:latest || exit 1

# hysds/pge-minimal
echo "#############################"
echo "Building hysds/pge-minimal"
echo "#############################"
docker build --rm --force-rm -t hysds/pge-minimal:${REL_DATE} -f Dockerfile.hysds-pge-minimal --build-arg id=$ID --build-arg gid=$GID . || exit 1
docker tag hysds/pge-minimal:${REL_DATE} hysds/pge-minimal:latest || exit 1
docker push hysds/pge-minimal:${REL_DATE} || exit 1
docker push hysds/pge-minimal:latest || exit 1

# hysds/redis
echo "#############################"
echo "Building hysds/redis"
echo "#############################"
docker build --rm --force-rm -t hysds/redis:${REL_DATE} -f Dockerfile.hysds-redis /home/ops || exit 1
docker tag hysds/redis:${REL_DATE} hysds/redis:latest || exit 1
docker push hysds/redis:${REL_DATE} || exit 1
docker push hysds/redis:latest || exit 1

# hysds/elasticsearch
echo "#############################"
echo "Building hysds/elasticsearch"
echo "#############################"
docker build --rm --force-rm -t hysds/elasticsearch:1.7 -f Dockerfile.hysds-elasticsearch /home/ops || exit 1
docker tag hysds/elasticsearch:1.7 hysds/elasticsearch:latest || exit 1
docker push hysds/elasticsearch:1.7 || exit 1
docker push hysds/elasticsearch:latest || exit 1

# hysds/rabbitmq
echo "#############################"
echo "Building hysds/rabbitmq"
echo "#############################"
docker build --rm --force-rm -t hysds/rabbitmq:3-management -f Dockerfile.hysds-rabbitmq /home/ops || exit 1
docker tag hysds/rabbitmq:3-management hysds/rabbitmq:latest || exit 1
docker push hysds/rabbitmq:3-management || exit 1
docker push hysds/rabbitmq:latest || exit 1

# build worker hysds components
for i in pge-base verdi; do
  echo "#############################"
  echo "Building hysds/$i"
  echo "#############################"
  docker build --rm --force-rm -t hysds/${i}:${REL_DATE} -f Dockerfile.hysds-${i} --build-arg id=$ID --build-arg gid=$GID /home/ops || exit 1
  docker tag hysds/${i}:${REL_DATE} hysds/${i}:latest || exit 1
  docker push hysds/${i}:${REL_DATE} || exit 1
  docker push hysds/${i}:latest || exit 1
done

# export verdi
cd /data/docker_images/
docker save hysds/verdi:${REL_DATE} > hysds-verdi-${REL_DATE}.tar; echo "done saving"; pigz -f hysds-verdi-${REL_DATE}.tar
docker save hysds/verdi:latest > hysds-verdi-latest.tar; echo "done saving"; pigz -f hysds-verdi-latest.tar
cd -

# build hysds components
for i in mozart metrics grq ci; do
  echo "#############################"
  echo "Building hysds/$i"
  echo "#############################"
  docker build --rm --force-rm -t hysds/${i}:${REL_DATE} -f Dockerfile.hysds-${i} --build-arg id=$ID --build-arg gid=$GID /home/ops || exit 1
  docker tag hysds/${i}:${REL_DATE} hysds/${i}:latest || exit 1
  docker push hysds/${i}:${REL_DATE} || exit 1
  docker push hysds/${i}:latest || exit 1
done
