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
mkdir ./backend/tmp
mkdir ./backend/tmp/data
mv ./backend/.flaskenv.template ./backend/.flaskenv