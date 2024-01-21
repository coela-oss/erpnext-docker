# Enterprise to Always

This repository include the setup script for Self hosting ERP Next on WSL or Linux.

Run on Windows, remove ```platform: linux/amd64``` from each compose file.

## Overview

System summary

* Traefik
* MariaDB
* Redis
* Frappe/ERPNext
* ERPNext setup tools
* Neko Remote web browser (as simple RDP)

## (Pre)Install Docker

Debian

https://docs.docker.com/engine/install/debian/

## Create Shared Volume

```
docker volume create erpnext-db
docker volume create erpnext-redis-cache
docker volume create erpnext-redis-queue
docker volume create erpnext-logs
docker volume create erpnext-sites
```

## Clone this repository

```
git clone https://github.com/hatakuya/e2a.git
```

## Traefik setup

Network configure

```
cp traefik/traefik.env.sample traefik/traefik.env
```

default basic auth ```admin/changeit```

Change the password with following command.

```
echo 'HASHED_PASSWORD='$(openssl passwd -apr1 changeit | sed 's/\$/\$\$/g') >> traefik.env
```

Should use ```up -d --force-recreate``` after change environment variables if container started already.

```
docker compose --project-name traefik \
  --env-file traefik/traefik.env \
  -f traefik/compose.traefik.yaml \
  -f traefik/override.traefik-ssl.yaml up -d 
```

__if run localhost, exclude ssl yaml.__

```
docker compose --project-name traefik \
  --env-file traefik/traefik.env \
  -f traefik/compose.traefik.yaml up -d 
```

## Database setup

Set initial password only.

```
cp mariadb/mariadb.env.sample mariadb/mariadb.env
```

```
docker compose --project-name mariadb --env-file mariadb/mariadb.env -f mariadb/compose.mariadb-shared.yaml up -d
```


## Redis setup

```
docker compose --project-name redis -f redis/compose.redis.yaml up -d
```

## ERPNext

Configure and run erpnext containers.
This means set up the base of ERP Next(equals set up Frappe), so we should add new site before section.

```
docker compose --project-name configurator -f tools/compose.configurator.yaml up
docker compose --project-name erpnext -f ./compose.erpnext.yaml up -d
```

Create a new site ERP Next.

```
docker compose --project-name create-site -f tools/compose.create-site.yaml up
```

## TIPS

### Shutdown


```
docker compose --project-name redis down
docker compose --project-name mariadb down
docker compose --project-name traefik down
docker compose --project-name erpnext down

```

### Clean docker resource

```
docker rm $(docker ps -a -q)
docker rmi -f $(docker images -a -q)
docker volume rm $(docker volume ls -q)
docker network rm $(docker network ls -q)
docker system prune -a # remove cache
```

### Permission denied for sites directory

easy fix
```
useradd -u 1000 erpuser
usermod -aG root erpuser
chown -R erpuser:root
```
