# HySDS Cluster via docker-compose

## Geonames

Clone the grq puppet module and create the geonames data tarball for elasticsearch:
```
git clone https://github.com/hysds/grq
cd grq/files
cat elasticsearch-data.tbz2.0* > /tmp/elasticsearch-data.tbz2
```

## Set Environment

```
cd hysds-dockerfiles/cluster
export ES_HEAP_SIZE=`free -m | grep '^Mem' | awk '{print $2/2}'`
export HYSDS_HOME=`pwd`/data
```

## Extract Geonames

```
mkdir -p data/grq/elasticsearch/data
tar xjvf /tmp/elasticsearch-data.tbz2 -C /tmp/
mv /tmp/elasticsearch/product_cluster data/grq/elasticsearch/data/
```

## Start HySDS Cluster

```
docker-compose up
```

or to put in background:

```
docker-compose up -d
```

### Ensure geonames database was initiated fine: 

- GRQ ES: http://localhost:39200/_plugin/head/

### Ensure links to all HySDS interfaces are up:

- Figaro: https://localhost:10443/figaro
- Product FacetView: https://localhost:30443/search/
- CI: http://localhost:48081

### For initial Jenkins password, run:

```
docker-compose exec ci cat /home/ops/.jenkins/secrets/initialAdminPassword
```


## Stop HySDS Cluster

```
docker-compose down
```
