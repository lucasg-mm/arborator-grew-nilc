#!/bin/bash

# create ids
echo "arborator-grew" >> ./backend/keys/arborator-grew-appid.txt
echo "arborator-grew-id" >> ./backend/keys/arborator-grew-dev-appid.txt

# generating self signed certificates
openssl req -x509 -newkey rsa:4096 -nodes -out ./backend/keys/cert.pem -keyout ./backend/keys/arborator-grew-dev.pem -days 365
openssl req -x509 -newkey rsa:4096 -nodes -out ./backend/keys/cert.pem -keyout ./backend/keys/arborator-grew.pem -days 365

