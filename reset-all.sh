#!/bin/bash

docker compose --project-name erp-front down
docker compose --project-name erpnext down
docker compose --project-name redis down
docker compose --project-name mariadb down
docker compose --project-name traefik down
docker system prune -a # Check remove status
docker rm $(docker ps -a -q)
docker rmi -f $(docker images -a -q)
docker volume rm $(docker volume ls -q)
docker network rm $(docker network ls -q)
docker system prune -a # remove cache
