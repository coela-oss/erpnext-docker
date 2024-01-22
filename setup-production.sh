#!/bin/bash

docker volume create erpnext-db
docker volume create erpnext-redis-cache
docker volume create erpnext-redis-queue
docker volume create erpnext-logs
docker volume create erpnext-sites

docker compose --project-name traefik \
  --env-file traefik/traefik.env \
  -f traefik/compose.traefik.yaml \
  -f traefik/override.traefik-ssl.yaml up -d 

docker compose --project-name mariadb --env-file mariadb/mariadb.env -f mariadb/compose.mariadb-shared.yaml up -d
docker compose --project-name redis -f redis/compose.redis.yaml up -d

docker compose --project-name configurator \
  --env-file ./erpnext.env \
  -f tools/compose.configurator.yaml up

docker compose --project-name create-site \
  --env-file ./erpnext.env \
  -f tools/compose.create-site.yaml up

docker compose --project-name erpnext \
  --env-file ./erpnext.env \
  -f ./compose.erpnext.yaml up -d

docker compose --project-name erp-front -f \
  --env-file ./erpnext.env \
  -f ./compose.frontend.yaml \
  -f traefik/override.frontend-ssl.yaml up -d 
