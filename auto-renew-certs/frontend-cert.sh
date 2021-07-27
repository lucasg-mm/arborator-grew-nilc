#!/bin/bash

# gets path to the docker-compose file
compose_path="$(dirname $(dirname $(realpath $0)))/docker-compose.yml"

# restarts frontend service to get another ad-hoc
# certificate
docker-compose -f $compose_path down frontend
docker-compose -f $compose_path up frontend