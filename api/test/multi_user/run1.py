#!/usr/bin/env python3
import sys
sys.path.append('..')
from utils import *

ping ()

project_id = "test_multi_user"
sample_id = "sample"

print ("\n***************************************************************************\n")
print ('========== [eraseProject]')
print ('       ... project_id -> ' + project_id)
reply = send_request ('eraseProject', data={'project_id': project_id})
check_reply (reply, None)

print ("\n***************************************************************************\n")
print ('========== [newProject]')
print ('       ... project_id -> ' + project_id)
reply = send_request ('newProject', data={'project_id': project_id})
check_reply (reply, None)

print ("\n***************************************************************************\n")
print ('========== [newSample]')
print ('       ... project_id -> ' + project_id)
print ('       ... sample_id -> ' + sample_id)
reply = send_request ('newSample', data={'project_id': project_id, 'sample_id': sample_id })
check_reply (reply, None)

user_ids = ['alice', 'bob', 'charlie']
conll_file = "fr_gsd-ud-test_00006.conllu"

print ("\n***************************************************************************\n")
print ('========== [saveConll] ')
print ('       ... project_id -> ' + project_id)
print ('       ... sample_id -> ' + sample_id)
print ('       ... user_id -> alice, bob & charlie')
print ('       ... conll_file -> ' + conll_file)
for user_id in user_ids:
    print (user_id)
    with open(conll_file+"_"+user_id, 'rb') as f:
        reply = send_request (
            'saveConll',
            data = {'project_id': project_id, 'sample_id': sample_id, 'user_id': user_id },
            files={'conll_file': f},
            )
        check_reply (reply, None)

