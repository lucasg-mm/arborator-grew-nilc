#!/usr/bin/env python3
import sys
sys.path.append('..')
from utils import *

ping ()

project_id = "big_request"
sample_id = "IBA_32_Tori-By-Samuel_MG"

print ("\n***************************************************************************\n")
print ('========== [eraseProject]')
print ('       ... project_id -> ' + project_id)
reply = send_request ('eraseProject', data={'project_id': project_id})
check_reply (reply, None)

