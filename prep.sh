#!/bin/bash

# >> prep work for the API <<
mkdir ./api/upload
mkdir ./api/storage
mkdir ./api/log
mkdir ./api/extern
mkdir ./api/static/
mkdir ./api/static/export

# >> prep work for the backend <<
mkdir ./backend/keys
mkdir ./backend/logs
mkdir ./backend/app/tmp
mkdir ./backend/app/tmp/data
cp ./backend/.flaskenv.template ./backend/.flaskenv

# create ids
echo "arborator-grew" >> ./backend/keys/arborator-grew-appid.txt
echo "arborator-grew-id" >> ./backend/keys/arborator-grew-dev-appid.txt

# generating self signed certificates
openssl req -x509 -newkey rsa:4096 -nodes -out ./backend/keys/cert.pem -keyout ./backend/keys/arborator-grew-dev.pem -days 365 < ./cert_template.txt
openssl req -x509 -newkey rsa:4096 -nodes -out ./backend/keys/cert.pem -keyout ./backend/keys/arborator-grew.pem -days 365 < ./cert_template.txt