# ERP Next Docker(WIP)

Self hosting ERP Next on WSL or Linux to organize ERPNext's docker compose can build it instantly.

It trades simplicity for availability, may be useful for those who have tried the official instructions and want to understand more detailed the process install.

I mainly use in Ubuntu/Debian, if on Windows, remove ```platform: linux/amd64``` from each compose file.

Refer [frappe/frappe_docker](https://github.com/frappe/frappe_docker.git) and added submodules.

## Services

* Traefik
  * for server on cloud or vps
  * localhost no proxy
* MariaDB
* Redis
* Frappe/ERPNext Backend
  * separating the background process
* ERPNext Frontend 
  * separated because it is related to traefik
* ERPNext setup tools
  * configure and create site step also separate
  * add frequently used commands
* Docker script
  * one shot install tool, reset all container ...etc
* (Option)Neko Remote web browser 
  * this is a bit of interest. is simple rdp necessary for erp next gen?

## (Pre)Install Docker

Debian

https://docs.docker.com/engine/install/debian/

## (Pre)Clone this repository

```
git clone https://github.com/hatakuya/e2a.git
```

## (Pre)Copy env template

3 env files required before ERPNext setup.
if run local, traefik.env not needed.

```
cp traefik/traefik.env.sample traefik/traefik.env
cp mariadb/mariadb.env.sample mariadb/mariadb.env
cp erpnext.env.sample erpnext.env
```

### traefik.env

This is necessary for configuring proxy settings.

```
TRAEFIK_DOMAIN=localhost
EMAIL=admin@example.com
HASHED_PASSWORD=$$apr1$$nt3s3Hgy$$7gI/Hasns4Xslvr5VhpY71
```

* TRAEFIK_DOMAIN 
  * the URL of the management screen
* EMAIL
  * Let'sEncrypt
* HASHED_PASSWORD
  * for basic authentication on the management screen

default basic auth ```admin/changeit```

Change the password with following command.

```
echo 'HASHED_PASSWORD='$(openssl passwd -apr1 changeit | sed 's/\$/\$\$/g') >> traefik.env
```

__Should use ```up -d --force-recreate``` after change environment variables if container started already.__


### mariadb.env

set only password

```
DB_PASSWORD=changeit
```

### erpnext.env

If use the official instructions, the minimum changes need to make are:

```
DB_PASSWORD=changeit
# Only if you use external database 
DB_HOST=mariadb
DB_PORT=3306
SITES=`localhost`
ROUTER=erpnext
BENCH_NETWORK=erpnext
```

It is important not to be misled by comments.

## Create Shared Volume

Define volumes first at the expense of availability.

```
docker volume create erpnext-db
docker volume create erpnext-redis-cache
docker volume create erpnext-redis-queue
docker volume create erpnext-logs
docker volume create erpnext-sites
```

## Traefik setup(Skip if set up localhost)

```
docker compose --project-name traefik \
  --env-file traefik/traefik.env \
  -f traefik/compose.traefik.yaml \
  -f traefik/override.traefik-ssl.yaml up -d 
```

## Database setup

Just a run.

### MariaDB

```
docker compose --project-name mariadb --env-file mariadb/mariadb.env -f mariadb/compose.mariadb-shared.yaml up -d
```

### Redis

```
docker compose --project-name redis -f redis/compose.redis.yaml up -d
```

## ERPNext

Build it step by step.

### Configurator

DB recognition and using Frappe application define.
keywords: app.txt common_site_config.json

```
docker compose --project-name configurator \
  --env-file ./erpnext.env \
  -f tools/compose.configurator.yaml up
```

This means complete set up the base of ERP Next(equals set up Frappe Platform), so we could add a new site next section.

### Create Site

Create a new site ERP Next.

```
docker compose --project-name create-site -f tools/compose.create-site.yaml up
```

### Run backend process

Front could not start without backend.

```
docker compose --project-name erpnext \
  --env-file ./erpnext.env \
  -f ./compose.erpnext.yaml up -d
```

It can run without data for erp next because of the backend is only Frappe framework.

### Run frontend process

```
docker compose --project-name erp-front \
  --env-file ./erpnext.env \
  -f ./compose.frontend.yaml up -d
```

localhost

```
http://localhost:8080
```

server host

```https://[erpnext.env SITE]
```

## TIPS

### Bench

```
docker compose --project-name erpnext exec backend bench --help
```

### Shutdown

```
docker compose --project-name erp-frontend down
docker compose --project-name erpnext down
docker compose --project-name redis down
docker compose --project-name mariadb down
docker compose --project-name traefik down
```

### Clean docker resource

```
docker rm $(docker ps -a -q)
docker rmi -f $(docker images -a -q)
docker volume rm $(docker volume ls -q)
docker network rm $(docker network ls -q)
docker system prune -a # remove cache
```
