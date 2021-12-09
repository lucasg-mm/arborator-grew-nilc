#!/bin/bash

# This is a script to renew the SSL certificates in the project.
# You can run this manually each year (365 days),
# or set it up as a cron job.

# gets root path to the docker-compose file
root_path="$(dirname $(dirname $(realpath $0)))"

# stops containers
/usr/local/bin/docker-compose -f $root_path/docker-compose.yml down

# renews backend certificate
openssl req -x509 -newkey rsa:4096 -nodes -out $root_path/backend/keys/cert.pem -keyout $root_path/backend/keys/arborator-grew-dev.pem -days 365 < $root_path/project_management_scripts/cert_template.txt
openssl req -x509 -newkey rsa:4096 -nodes -out $root_path/backend/keys/cert.pem -keyout $root_path/backend/keys/arborator-grew.pem -days 365 < $root_path/project_management_scripts/cert_template.txt

# renews frontend certificate
openssl req -x509 -newkey rsa:4096 -nodes -out $root_path/frontend/keys/cert.pem -keyout $root_path/frontend/keys/arborator-grew-dev.pem -days 365 < $root_path/project_management_scripts/cert_template.txt
openssl req -x509 -newkey rsa:4096 -nodes -out $root_path/frontend/keys/cert.pem -keyout $root_path/frontend/keys/arborator-grew.pem -days 365 < $root_path/project_management_scripts/cert_template.txt

# starts containers again
/usr/local/bin/docker-compose -f $root_path/docker-compose.yml up
