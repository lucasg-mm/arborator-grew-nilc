#!/usr/bin/env python3

from termcolor import colored
import json
import sys
import requests

if (len(sys.argv) > 1 and sys.argv[1] == "prod"):
    server = 'https://frontend:8080'
elif (len(sys.argv) > 1 and sys.argv[1] == "dev"):
    server = 'https://frontend:8080'
else:
    server = 'https://frontend:8080'


def send_request(fct_name, data={}, files={}):
    try:
        r = requests.post(
            "%s/%s" % (server, fct_name),
            files=files,
            data=data
        )
        return r.json()
    except requests.ConnectionError:
        print("Connection refused")
    except Exception as e:
        print("Uncaught exception, please report %s" % e)
        print(e)


def parse_reply(reply):
    if reply['status'] == "ERROR":
        print(colored(reply['data'], 'red'))
        return None
    elif reply['status'] == "OK":
        return (reply['data'])
    else:
        print(colored(reply, 'blue'))
        return None


def check_reply(reply, expected):
    if reply['status'] == "ERROR":
        print(colored(reply['data'], 'red'))
    elif reply['status'] == "OK":
        if reply['data'] == expected:
            print(colored('+++++ OK +++++', 'green'))
        else:
            print(colored('----- KO -----', 'yellow'))
            print("==================== Expected ====================")
            print(expected)
            print("==================== Reply =======================")
            print(
                colored(json.dumps(reply['data'], indent=4, sort_keys=True), 'yellow'))
            print("==================================================")
    else:
        print(colored(reply, 'blue'))
        return None


def check_reply_list(reply, expected_lenght):
    out = parse_reply(reply)
    if isinstance(out, list) and len(out) == expected_lenght:
        print(colored('+++++ OK: |reply|=%s +++++' % expected_lenght, 'green'))
    else:
        print(colored('----- KO -----', 'yellow'))
        print("==================== Reply =======================")
        print(colored(json.dumps(out, indent=4, sort_keys=True), 'yellow'))
        print("==================================================")


def check_reply_dict(reply, expected_lenght):
    out = parse_reply(reply)
    if isinstance(out, dict) and len(out) == expected_lenght:
        print(colored('+++++ OK: |reply|=%s +++++' % expected_lenght, 'green'))
    else:
        print(colored('----- KO -----', 'yellow'))
        print("==================== Reply =======================")
        print(colored(json.dumps(out, indent=4, sort_keys=True), 'yellow'))
        print("==================================================")


def ping():
    x = send_request('ping')
    if x is None:
        print(colored("Cannot connect to: %s" % server, "red"))
        exit(1)
    else:
        print(colored("Connection ok to: %s" % server, "green"))
