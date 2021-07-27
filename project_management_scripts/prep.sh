#!/bin/bash

# gets the root directory of the project
root_path="$(dirname $(dirname $(realpath $0)))"

# >> prep work for the API <<

mkdir $root_path/api/upload
mkdir $root_path/api/storage
mkdir $root_path/api/log
mkdir $root_path/api/extern
mkdir $root_path/api/static/
mkdir $root_path/api/static/export


# >> prep work for the backend <<

mkdir $root_path/backend/keys
mkdir $root_path/backend/logs
mkdir $root_path/backend/app/tmp
mkdir $root_path/backend/app/tmp/data
cp $root_path/backend/.flaskenv.template $root_path/backend/.flaskenv

# create ids
echo "arborator-grew" >> $root_path/backend/keys/arborator-grew-appid.txt
echo "arborator-grew-id" >> $root_path/backend/keys/arborator-grew-dev-appid.txt


# >> prep work for the frontend <<

mkdir $root_path/frontend/keys


# >> generating self signed certificates <<

# creates backend certificate
openssl req -x509 -newkey rsa:4096 -nodes -out $root_path/backend/keys/cert.pem -keyout $root_path/backend/keys/arborator-grew-dev.pem -days 365 < $root_path/project_management_script/cert_template.txt
openssl req -x509 -newkey rsa:4096 -nodes -out $root_path/backend/keys/cert.pem -keyout $root_path/backend/keys/arborator-grew.pem -days 365 < $root_path/project_management_script/cert_template.txt

# creates frontend certificate
openssl req -x509 -newkey rsa:4096 -nodes -out $root_path/frontend/keys/cert.pem -keyout $root_path/frontend/keys/arborator-grew-dev.pem -days 365 < $root_path/project_management_script/cert_template.txt
openssl req -x509 -newkey rsa:4096 -nodes -out $root_path/frontend/keys/cert.pem -keyout $root_path/frontend/keys/arborator-grew.pem -days 365 < $root_path/project_management_script/cert_template.txt
