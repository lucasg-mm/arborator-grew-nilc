#!/usr/bin/env python3

from utils import *

ping ()

project_id = "rewrite"
sample_id = "sample"
user_id = "bruno"

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
reply = send_request ('newSample', data={'project_id': project_id, 'sample_id': sample_id})
check_reply (reply, None)


print ("\n***************************************************************************\n")
conll_graph = """1	Aviator	Aviator	PROPN	_	_	0	root	_	SpaceAfter=No
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
reply = send_request ('saveGraph', data={'project_id': project_id, 'sample_id': sample_id, 'sent_id': 'fr-ud-dev_00001', 'user_id': user_id, 'conll_graph': conll_graph})
check_reply (reply, None)

print ("\n***************************************************************************\n")
conll_graph = """
1	Mais	mais	CCONJ	_	_	3	cc	_	wordform=mais
2	comment	comment	ADV	_	_	3	mod	_	_
3	faire	faire	VERB	_	VerbForm=Inf	0	root	_	_
4	dans	dans	ADP	_	_	3	mod	_	_
5	un	un	DET	_	Definite=Ind|Gender=Masc|Number=Sing|PronType=Art	6	det	_	_
6	contexte	contexte	NOUN	_	Gender=Masc|Number=Sing	4	comp:obj	_	_
7	structurellement	structurellement	ADV	_	_	8	mod	_	_
8	raciste	raciste	ADJ	_	Gender=Masc|Number=Sing	6	mod	_	_
9	?	?	PUNCT	_	_	3	punct	_	_
"""
print ('========== [saveGraph] ')
print ('       ... project_id -> ' + project_id)
print ('       ... sample_id -> ' + sample_id)
print ('       ... user_id -> ' + user_id)
print ('       ... graph -> fr-ud-dev_00003')
reply = send_request ('saveGraph', data={'project_id': project_id, 'sample_id': sample_id, 'sent_id': 'fr-ud-dev_00003', 'user_id': user_id, 'conll_graph': conll_graph})
check_reply (reply, None)

pattern = 'pattern { N [upos=NOUN] }'
commands = 'commands { N.upos = NC }'

print ("\n***************************************************************************\n")
print ('========== [searchPatternInGraphs]')
print ('       ... project_id -> ' + project_id)
print ('       ... pattern -> ' + pattern)
reply = send_request ('searchPatternInGraphs', data={'project_id': project_id, 'pattern': pattern })
out=parse_reply (reply)
if isinstance(out, list) and len(out) == 3:
    print(colored('+++++ OK +++++', 'green'))
else:
    print(colored('----- KO -----', 'yellow'))
    print ("==================== Reply =======================")
    print(colored(json.dumps(out, indent=4, sort_keys=True),'yellow'))
    print ("==================================================")


print ("\n***************************************************************************\n")
print ('========== [tryRule]')
print ('       ... project_id -> ' + project_id)
print ('       ... pattern -> ' + pattern)
print ('       ... commands -> ' + commands)
reply = send_request ('tryRule', data={'project_id': project_id, 'pattern': pattern, 'commands': commands})
out=parse_reply (reply)
if isinstance(out, list) and len(out) == 2:
    print(colored('+++++ OK +++++', 'green'))
    print(colored(json.dumps(out, indent=4, sort_keys=True),'green'))
else:
    print(colored('----- KO -----', 'yellow'))
    print ("==================== Reply =======================")
    print(colored(json.dumps(out, indent=4, sort_keys=True),'yellow'))
    print ("==================================================")


print ("\n***************************************************************************\n")
print ('========== [applyRule]')
print ('       ... project_id -> ' + project_id)
print ('       ... pattern -> ' + pattern)
print ('       ... commands -> ' + commands)
reply = send_request ('applyRule', data={'project_id': project_id, 'pattern': pattern, 'commands': commands})
check_reply (reply, {'rewritten': 2, 'unchanged': 0})
print(colored(json.dumps(parse_reply (reply), indent=4, sort_keys=True),'green'))


print ("\n***************************************************************************\n")
print ('========== [searchPatternInGraphs]')
print ('       ... project_id -> ' + project_id)
print ('       ... pattern -> ' + pattern)
reply = send_request ('searchPatternInGraphs', data={'project_id': project_id, 'pattern': pattern })
check_reply (reply, [])


print ("\n***************************************************************************\n")
print ('========== [tryRule]')
print ('       ... project_id -> ' + project_id)
print ('       ... pattern -> ' + pattern)
print ('       ... commands -> ' + commands)
reply = send_request ('tryRule', data={'project_id': project_id, 'pattern': pattern, 'commands': commands})
check_reply (reply, [])


print ("\n***************************************************************************\n")
pattern = 'pattern { N [upos=VERB] }'
commands = 'commands { N.upos = V }'
print ('========== [applyRule]')
print ('       ... project_id -> ' + project_id)
print ('       ... pattern -> ' + pattern)
print ('       ... commands -> ' + commands)
reply = send_request ('applyRule', data={'project_id': project_id, 'pattern': pattern, 'commands': commands})
check_reply (reply, {'rewritten': 1, 'unchanged': 1})
#
# print ("\n***************************************************************************\n")
# print ('========== [eraseProject]')
# print ('       ... project_id -> ' + project_id)
# reply = send_request ('eraseProject', data={'project_id': project_id})
# check_reply (reply, None)
