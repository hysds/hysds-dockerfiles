# HySDS Dockerfiles

Install Docker
--------------

Follow instructions at https://github.com/hysds/puppet-docker


Set .dockerignore
-----------------

```
cp .dockerignore ~/
```


CentOS 7
--------

```
docker pull docker.io/centos:7
docker build --rm --force-rm -t hysds/centos:7 -f Dockerfile.hysds-centos7 .
```


CentOS 7 with systemd enabled
-----------------------------

```
docker build --rm --force-rm -t hysds/centos-systemd:7 -f Dockerfile.hysds-centos7-systemd .
```


Minimal Image for PGE
---------------------

```
docker build --rm --force-rm -t hysds/pge-minimal:<YYYYMMDD> -f Dockerfile.hysds-pge-minimal \
       --build-arg id=$ID --build-arg gid=`id -g` .
```


Minimal Image for HySDS PGE (contains HySDS verdi component)
------------------------------------------------------------

```
docker build --rm --force-rm -t hysds/pge-base:<YYYYMMDD> -f Dockerfile.hysds-pge-base \
       --build-arg git_oauth_token=<token> --build-arg id=$ID \
       --build-arg gid=`id -g` /home/ops
```


ARIA PGE Image (based on Mimimal Image for HySDS PGE)
-----------------------------------------------------

Use cache:
```
docker build --rm --force-rm -t hysds/pge-aria:<YYYYMMDD> -f Dockerfile.hysds-pge-aria \
       --build-arg git_oauth_token=<token> /home/ops
```

No cache:
```
docker build --no-cache --rm --force-rm -t hysds/pge-aria:<YYYYMMDD> \
       -f Dockerfile.hysds-pge-aria --build-arg git_oauth_token=<token> /home/ops
```

Export Container
----------------

```
docker save hysds/pge-aria-dev:<YYYYMMDD> > pge-aria-dev_<YYYYMMDD>.tar
gzip pge-aria-dev_<YYYYMMDD>.tar
aws s3 cp pge-aria-dev_<YYYYMMDD>.tar.gz s3://hysds-aria-code-bucket/
```


Mozart
------

1. Prepare directories:

```
cd /home/ops
mkdir repos
cd repos
# clone all HySDS repos (hysds, osaka, sciflo, mozart, etc.) here
export ES_HEAP_SIZE=`free -m | grep '^Mem' | awk '{print $2/2}'`
export HYSDS_HOME=/data
mkdir -p $HYSDS_HOME/mozart/rabbitmq
mkdir -p $HYSDS_HOME/mozart/redis
mkdir -p $HYSDS_HOME/mozart/elasticsearch
mkdir -p $HYSDS_HOME/mozart/etc
mkdir -p $HYSDS_HOME/mozart/log
cp ~/mozart_configs/* $HYSDS_HOME/mozart/etc/
cp -rp ~/aws_creds/.aws ~/aws_creds/.s3cfg ~/aws_creds/.boto /home/ops/
echo "machine <FQDN> login guest password guest" > /home/ops/.netrc
echo "macdef init" >> /home/ops/.netrc
echo "" >> /home/ops/.netrc
chmod 600 /home/ops/.netrc
```

2. Build mozart container:
```
cd /home/ops/hysds-dockerfiles
docker build --rm --force-rm -t hysds/mozart:<YYYYMMDD> -f Dockerfile.hysds-mozart \
       --build-arg git_oauth_token=<token> --build-arg id=$ID \
       --build-arg gid=`id -g` /home/ops
docker tag hysds/mozart:<YYYYMMDD> hysds/mozart:latest
```

3. Run mozart via docker:
```
docker run -d --hostname mozart --name mozart --link mozart-rabbit:rabbit \
       --link mozart-redis:redis --link mozart-elasticsearch:elasticsearch -p 80:80 \
       -p 443:443 -p 5555:5555 -p 8888:8888 -p 9001:9001 -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
       -v /data/mozart/etc:/home/ops/mozart/etc -v /data/mozart/log:/home/ops/mozart/log \
       -v /home/ops/.aws:/home/ops/.aws -v /home/ops/.boto:/home/ops/.boto \
       -v /home/ops/.s3cfg:/home/ops/.s3cfg --volumes-from mozart-redis \
       -v /var/run/docker.sock:/var/run/docker.sock hysds/mozart:<YYYYMMDD>
```

or via docker-compose:

```
cd /home/ops/hysds-dockerfiles/mozart
docker-compose up
```


Metrics
-------

1. Prepare directories:

```
cd /home/ops
mkdir repos
cd repos
# clone all HySDS repos (hysds, osaka, sciflo, mozart, etc.) here
export ES_HEAP_SIZE=`free -m | grep '^Mem' | awk '{print $2/2}'`
export HYSDS_HOME=/data
export METRICS_FQDN=<host FQDN>
mkdir -p $HYSDS_HOME/metrics/rabbitmq
mkdir -p $HYSDS_HOME/metrics/redis
mkdir -p $HYSDS_HOME/metrics/elasticsearch
mkdir -p $HYSDS_HOME/metrics/etc
mkdir -p $HYSDS_HOME/metrics/log
cp ~/metrics_configs/* $HYSDS_HOME/metrics/etc/
cp -rp ~/aws_creds/.aws ~/aws_creds/.s3cfg ~/aws_creds/.boto /home/ops/
echo "machine <FQDN> login guest password guest" > /home/ops/.netrc
echo "macdef init" >> /home/ops/.netrc
echo "" >> /home/ops/.netrc
chmod 600 /home/ops/.netrc
```

2. Build metrics container:
```
cd /home/ops/hysds-dockerfiles
docker build --rm --force-rm -t hysds/metrics:<YYYYMMDD> -f Dockerfile.hysds-metrics \
       --build-arg git_oauth_token=<token> --build-arg id=$ID \
       --build-arg gid=`id -g` /home/ops
docker tag hysds/metrics:<YYYYMMDD> hysds/metrics:latest
```

3. Run metrics via docker:
```
docker run -d --hostname metrics --name metrics --link metrics-redis:redis \
       --link metrics-elasticsearch:elasticsearch -p 80:80  -p 443:443 -p 5555:5555 \
       -p 8888:8888 -p 9001:9001 -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
       -v /data/metrics/etc:/home/ops/metrics/etc -v /data/metrics/log:/home/ops/metrics/log \
       -v /home/ops/.aws:/home/ops/.aws -v /home/ops/.boto:/home/ops/.boto \
       -v /home/ops/.s3cfg:/home/ops/.s3cfg --volumes-from metrics-redis \
       -v /var/run/docker.sock:/var/run/docker.sock hysds/metrics:<YYYYMMDD>
```

or via docker-compose:

```
cd /home/ops/hysds-dockerfiles/metrics
docker-compose up
```


GRQ
---

1. Prepare directories:

```
cd /home/ops
mkdir repos
cd repos
# clone all HySDS repos (hysds, osaka, sciflo, mozart, etc.) here
export ES_HEAP_SIZE=`free -m | grep '^Mem' | awk '{print $2/2}'`
export HYSDS_HOME=/data
mkdir -p $HYSDS_HOME/grq/redis
mkdir -p $HYSDS_HOME/grq/elasticsearch
mkdir -p $HYSDS_HOME/grq/etc
mkdir -p $HYSDS_HOME/grq/log
cp ~/grq_configs/* $HYSDS_HOME/grq/etc/
cp -rp ~/aws_creds/.aws ~/aws_creds/.s3cfg ~/aws_creds/.boto /home/ops/
```

2. Build grq container:
```
cd /home/ops/hysds-dockerfiles
docker build --rm --force-rm -t hysds/grq:<YYYYMMDD> -f Dockerfile.hysds-grq \
       --build-arg git_oauth_token=<token> --build-arg id=$ID \
       --build-arg gid=`id -g` /home/ops
docker tag hysds/grq:<YYYYMMDD> hysds/grq:latest
```

3. Run grq via docker:
```
docker run -d --hostname grq --name grq --link grq-redis:redis \
       --link grq-elasticsearch:elasticsearch -p 80:80  -p 443:443 -p 5555:5555 \
       -p 8888:8888 -p 9001:9001 -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
       -v /data/grq/etc:/home/ops/sciflo/etc -v /data/grq/log:/home/ops/sciflo/log \
       -v /home/ops/.aws:/home/ops/.aws -v /home/ops/.boto:/home/ops/.boto \
       -v /home/ops/.s3cfg:/home/ops/.s3cfg -v /var/run/docker.sock:/var/run/docker.sock \
       hysds/grq:<YYYYMMDD>
```

or via docker-compose:

```
cd /home/ops/hysds-dockerfiles/grq
docker-compose up
```


Verdi
-----

1. Prepare directories:

```
cd /home/ops
mkdir repos
cd repos
# clone all HySDS repos (hysds, osaka, sciflo, mozart, etc.) here
export ES_HEAP_SIZE=`free -m | grep '^Mem' | awk '{print $2/2}'`
export HYSDS_HOME=/data
mkdir -p $HYSDS_HOME/verdi/etc
mkdir -p $HYSDS_HOME/verdi/log
cp ~/verdi_configs/* $HYSDS_HOME/verdi/etc/
cp -rp ~/aws_creds/.aws ~/aws_creds/.s3cfg ~/aws_creds/.boto /home/ops/
```

2. Build verdi container:
```
cd /home/ops/hysds-dockerfiles
docker build --rm --force-rm -t hysds/verdi:<YYYYMMDD> -f Dockerfile.hysds-verdi \
       --build-arg git_oauth_token=<token> --build-arg id=$ID \
       --build-arg gid=`id -g` /home/ops
docker tag hysds/verdi:<YYYYMMDD> hysds/verdi:latest
```

3. Run verdi via docker:
```
docker run -d --hostname verdi --name verdi -p 80:80  -p 443:443 -p 8085:8085 \
       -p 9001:9001 -p 46224:46224 -p 46224:26224/udp -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
       -v /data/verdi/etc:/home/ops/verdi/etc -v /data/verdi/log:/home/ops/verdi/log \
       -v /home/ops/.aws:/home/ops/.aws -v /home/ops/.boto:/home/ops/.boto \
       -v /home/ops/.s3cfg:/home/ops/.s3cfg -v /var/run/docker.sock:/var/run/docker.sock \
       hysds/verdi:<YYYYMMDD>
```

or via docker-compose:

```
cd /home/ops/hysds-dockerfiles/verdi
docker-compose up
```


CI
--

1. Prepare directories:

```
cd /home/ops
mkdir repos
cd repos
# clone all HySDS repos (hysds, osaka, sciflo, mozart, etc.) here
export ES_HEAP_SIZE=`free -m | grep '^Mem' | awk '{print $2/2}'`
export HYSDS_HOME=/data
mkdir -p $HYSDS_HOME/verdi/etc
mkdir -p $HYSDS_HOME/verdi/log
cp ~/verdi_configs/* $HYSDS_HOME/verdi/etc/
cp -rp ~/aws_creds/.aws ~/aws_creds/.s3cfg ~/aws_creds/.boto /home/ops/
```

2. Build CI container:
```
cd /home/ops/hysds-dockerfiles
docker build --rm --force-rm -t hysds/ci:<YYYYMMDD> -f Dockerfile.hysds-ci \
       --build-arg git_oauth_token=<token> --build-arg id=$ID \
       --build-arg gid=`id -g` /home/ops
docker tag hysds/ci:<YYYYMMDD> hysds/ci:latest
```

3. Run CI via docker:
```
docker run -d --hostname ci --name ci -p 80:80  -p 443:443 -p 8080:8080 \
       -p 9001:9001 -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
       -v /data/verdi/etc:/home/ops/verdi/etc -v /data/verdi/log:/home/ops/verdi/log \
       -v /home/ops/.aws:/home/ops/.aws -v /home/ops/.boto:/home/ops/.boto \
       -v /home/ops/.s3cfg:/home/ops/.s3cfg -v /var/run/docker.sock:/var/run/docker.sock \
       hysds/ci:<YYYYMMDD>
```

or via docker-compose:

```
cd /home/ops/hysds-dockerfiles/ci
docker-compose up
```
