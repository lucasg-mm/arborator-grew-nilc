#!/usr/bin/env python3
import sys
sys.path.append('..')
from utils import *

ping()

project_id = "test_multi_user"
sample_id = "sample"
sent_id = "fr-ud-dev_00001"
user_id = "bob"

print ("\n***************************************************************************\n")
conll_graph = """
# sent_id = fr-ud-dev_00001
1	Aviator	XXX	PROPN	_	_	0	root	_	SpaceAfter=No
2	,	,	PUNCT	_	_	4	punct	_	_
3	un	un	DET	_	Definite=Ind|Gender=Masc|Number=Sing|PronType=Art	4	det	_	_
4	film	film	NOUN	_	Gender=Masc|Number=Sing	1	appos	_	_
5	sur	sur	ADP	_	_	4	udep	_	_
6	la	le	DET	_	Definite=Def|Gender=Fem|Number=Sing|PronType=Art	7	det	_	_
7	vie	vie	NOUN	_	Gender=Fem|Number=Sing	5	comp:obj	_	_
8	de	de	ADP	_	_	7	udep	_	_
9	Hughes	Hughes	PROPN	_	_	8	comp:obj	_	SpaceAfter=No
10	.	.	PUNCT	_	_	1	punct	_	_
"""
print ('========== [saveGraph] ')
print ('       ... project_id -> ' + project_id)
print ('       ... sample_id -> ' + sample_id)
print ('       ... user_id -> ' + user_id)
print ('       ... graph -> fr-ud-dev_00001')
reply = send_request ('saveGraph', data={'project_id': project_id, 'sample_id': sample_id, 'user_id': user_id, 'sent_id': sent_id, 'conll_graph': conll_graph})
check_reply (reply, None)
print(reply)


