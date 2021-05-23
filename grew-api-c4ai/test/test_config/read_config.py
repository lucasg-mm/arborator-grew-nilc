#!/usr/bin/env python3
import sys
sys.path.append('..')
from utils import *

ping()

project_id = "test_config"

# update config
config = { "test": "config", "value": 12 }

print("\n***************************************************************************\n")
print('========== [getProjectConfig]')
print('       ... project_id -> ' + project_id)
reply = send_request('getProjectConfig', data={'project_id': project_id})
check_reply(reply, config)
