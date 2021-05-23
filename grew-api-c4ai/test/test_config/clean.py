#!/usr/bin/env python3
import sys
sys.path.append('..')
from utils import *

ping()

project_id = "test_config"

# erase project if exists to start a new test
print("\n***************************************************************************\n")
print('========== [eraseProject]')
print('       ... project_id -> ' + project_id)
reply = send_request('eraseProject', data={'project_id': project_id})
check_reply(reply, None)
