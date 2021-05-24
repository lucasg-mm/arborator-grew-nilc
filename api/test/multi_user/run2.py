#!/usr/bin/env python3
import sys
sys.path.append('..')
from utils import *

ping()

project_id = "test_multi_user"
sample_id = "sample"

print("\n***************************************************************************\n")
print('========== [searchPatternInGraphs]')
pattern = 'pattern { N[ lemma="match"] }'
print('       ... project_id -> %s' % project_id)
print('       ... pattern -> %s' % pattern)
reply = send_request(
    'searchPatternInGraphs',
    data={'project_id': project_id, 'pattern': pattern}
)
check_reply_list(reply,3)

print("\n***************************************************************************\n")
print('========== [searchPatternInGraphs]')
pattern = 'pattern { N[ lemma="match", upos="NOUN" ] }'
print('       ... project_id -> %s' % project_id)
print('       ... pattern -> %s' % pattern)
reply = send_request(
    'searchPatternInGraphs',
    data={'project_id': project_id, 'pattern': pattern}
)
check_reply_list(reply,1)

print("\n***************************************************************************\n")
print('========== [searchPatternInGraphs]')
pattern = 'global { sent_id = "fr-ud-test_00006" }'
print('       ... project_id -> %s' % project_id)
print('       ... pattern -> %s' % pattern)
reply = send_request(
    'searchPatternInGraphs',
    data={'project_id': project_id, 'pattern': pattern}
)
check_reply_list(reply,3)
