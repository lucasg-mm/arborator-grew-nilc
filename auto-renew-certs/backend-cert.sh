#!/bin/bash

# gets the path to the root directory of the project
root_path="$(dirname $(dirname $(realpath $0)))"

# generating self signed certificates for the next year
openssl req -x509 -newkey rsa:4096 -nodes -out $root_path/backend/keys/cert.pem -keyout $root_path/backend/keys/arborator-grew-dev.pem -days 365 < $root_path/cert_template.txt
openssl req -x509 -newkey rsa:4096 -nodes -out $root_path/backend/keys/cert.pem -keyout $root_path/backend/keys/arborator-grew.pem -days 365 < $root_path/cert_template.txt