#!/usr/bin/env python3

from utils import *

print ("\n***************************************************************************\n")

print ('========== [getProjects]')
reply = send_request ('getProjects')
print (reply)


project_id = "FraCas-French"
sample_id = "fracas_french_udpipe.retok"

print ('========== [getSamples]')
print ('       ... project_id -> %s' % project_id)
reply = send_request ('getSamples', data={'project_id': project_id})
print (reply)

print ('========== [getConll]')
print ('       ... project_id -> %s' % project_id)
print ('       ... sample_id -> %s' % sample_id)
reply = send_request ('getConll', data={'project_id': project_id, 'sample_id': sample_id})
check_reply_dict(reply, 878)

print ('========== [searchPatternInGraphs]')
pattern = 'pattern { N[ lemma = "commissaire"] }'
print ('       ... project_id -> %s' % project_id)
print ('       ... pattern -> %s' % pattern)
reply = send_request ('searchPatternInGraphs', data={'project_id': project_id, 'pattern': pattern})
check_reply_list(reply, 43)
