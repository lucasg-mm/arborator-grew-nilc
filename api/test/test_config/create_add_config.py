#!/usr/bin/env python3
import sys
sys.path.append('..')
from utils import *

ping()

project_id = "test_config"

# create project
print("\n***************************************************************************\n")
print('========== [newProject]')
print('       ... project_id -> ' + project_id)
reply = send_request('newProject', data={'project_id': project_id})
check_reply(reply, None)

# update config
config = '{ "test": "config", "value": 12 }'
print("\n***************************************************************************\n")
print('========== [updateProjectConfig]')
print('       ... project_id -> ' + project_id)
print('       ... config -> ' + config)
reply = send_request('updateProjectConfig', data={ 'project_id': project_id, 'config': config})
check_reply(reply, None)

