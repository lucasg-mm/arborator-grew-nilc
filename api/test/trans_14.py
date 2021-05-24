#!/usr/bin/env python3

from utils import *

#ping ()

project_id = "debug_gloss"
sample_id = "sample"
user_id = "bruno"

print ("\n***************************************************************************\n")
print ('========== [newProject]')
print ('       ... project_id -> ' + project_id)
reply = send_request ('newProject', data={'project_id': project_id})

if reply['status'] == "ERROR":
    print(colored('projet `%s` already exist, cannot run test' % project_id, 'red'))
    exit (0)

print ("\n***************************************************************************\n")
print ('========== [newSample]')
print ('       ... project_id -> ' + project_id)
print ('       ... sample_id -> ' + sample_id)
reply = send_request ('newSample', data={'project_id': project_id, 'sample_id': sample_id})
check_reply (reply, None)


print ("\n***************************************************************************\n")
conll_graph = """1	#	#	PUNCT	_	_	3	punct	_	AlignBegin=246974|AlignEnd=247510|Gloss=PUNCT
2	I	I	PRON	_	Case=Nom|Number=Sing|Person=1|PronType=Prs	3	subj	_	AlignBegin=247510|AlignEnd=247640|Gloss=NOM.SG.1
3	get	get	VERB	_	_	0	root	_	AlignBegin=247640|AlignEnd=247810|Gloss=get
4	mind	mind	NOUN	_	_	3	comp:obj@lvc	_	AlignBegin=247810|AlignEnd=248107|Gloss=mind
5	sey	sey	SCONJ	_	_	3	comp:obj	_	AlignBegin=248107|AlignEnd=248530|Gloss=COMP
6	[	[	PUNCT	_	_	8	punct	_	AlignBegin=248530|AlignEnd=248560|Gloss=PUNCT
7	I	I	PRON	_	Case=Nom|Number=Sing|Person=1|PronType=Prs	8	subj	_	AlignBegin=248560|AlignEnd=248716|Gloss=NOM.SG.1
8	go	go	AUX	_	Aspect=Prosp	5	comp:obj	_	AlignBegin=248716|AlignEnd=249358|Gloss=PROSP
9	join	join	VERB	_	_	8	comp:aux	_	AlignBegin=249358|AlignEnd=249816|Gloss=join
10	politics	politics	NOUN	_	Number=Plur	9	comp:obj	_	AlignBegin=249816|AlignEnd=250744|Gloss=politics.PL
11	]	]	PUNCT	_	_	8	punct	_	AlignBegin=250744|AlignEnd=250774|Gloss=PUNCT
12	//	//	PUNCT	_	_	3	punct	_	AlignBegin=250744|AlignEnd=250774|Gloss=PUNCT
"""
print ('========== [saveGraph] ')
print ('       ... project_id -> ' + project_id)
print ('       ... sample_id -> ' + sample_id)
print ('       ... user_id -> ' + user_id)
print ('       ... graph -> naija')
reply = send_request ('saveGraph', data={'project_id': project_id, 'sample_id': sample_id, 'sent_id': 'naija', 'user_id': user_id, 'conll_graph': conll_graph})
check_reply (reply, None)

old_pattern = 'pattern { N [form="//", _MISC_Gloss="PUNCT"] }'
new_pattern = 'pattern { N [form="//", Gloss="PUNCT"] }'

print ("\n***************************************************************************\n")
print ('========== [searchPatternInGraphs]')
print ('       ... project_id -> ' + project_id)
print ('       ... pattern -> ' + old_pattern)
old = parse_reply(send_request ('searchPatternInGraphs', data={'project_id': project_id, 'pattern': old_pattern }))

print ("\n***************************************************************************\n")
print ('========== [searchPatternInGraphs]')
print ('       ... project_id -> ' + project_id)
print ('       ... pattern -> ' + new_pattern)
new = parse_reply(send_request ('searchPatternInGraphs', data={'project_id': project_id, 'pattern': new_pattern }))

print ("old: %d" %len (old))
print ("new: %d" %len (new))

print ("\n***************************************************************************\n")
print ('========== [eraseProject]')
print ('       ... project_id -> ' + project_id)
reply = send_request ('eraseProject', data={'project_id': project_id})
check_reply (reply, None)

