#!/usr/bin/env python3
import sys
sys.path.append('..')
from utils import *

ping ()

project_id = "big_request"
sample_id = "IBA_32_Tori-By-Samuel_MG"

print ("\n***************************************************************************\n")
print ('========== [newProject]')
print ('       ... project_id -> ' + project_id)
reply = send_request ('newProject', data={'project_id': project_id})
if reply["status"] == "ERROR":
    print (colored (reply["message"], "red"))
    exit(0)
else:
    check_reply (reply, None)

#check_reply (reply, None)

print ("\n***************************************************************************\n")
print ('========== [newSample]')
print ('       ... project_id -> ' + project_id)
print ('       ... sample_id -> ' + sample_id)
reply = send_request ('newSample', data={'project_id': project_id, 'sample_id': sample_id })
check_reply (reply, None)

with open('big.json') as json_file:
    data = json.load(json_file)
    tree = data["trees"][0]
    conll_graph = tree["conll"]
    sample_id = tree["sample_name"]
    sent_id = tree["sent_id"]
    user_id = data["user_id"]
    print(sample_id)
    reply = send_request ('saveGraph', data={'project_id': project_id, 'sample_id': sample_id, 'sent_id': sent_id, 'user_id': user_id, 'conll_graph': conll_graph })
    print (reply)