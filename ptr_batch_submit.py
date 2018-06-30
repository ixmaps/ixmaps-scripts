#!/usr/bin/python

#curl -d "@IXMaps_20170315T04_59_43Z_494943.txt" -X POST https://www.ixmaps.ca/application/controller/geoloc_ptr.php

import os
import sys
import string
import requests
import json

def json_validator(data):
  try:
    json.loads(data)
    return True
  except ValueError as error:
    print("invalid json: %s" % error)
    return False


outfile = open('ptr_submission_returns.out', 'r+')
# delete contents of file
outfile.seek(0)
outfile.truncate()

num_files = len([name for name in os.listdir('.')])

for count, filename in enumerate(os.listdir('.'), start=1):
# for index, filename in os.listdir('.'):
  if filename.endswith(".txt"):
    print(str(100 * float(count)/float(num_files))+'% complete')
    route = open(filename, 'r+')
    r = requests.post("https://www.ixmaps.ca/application/controller/geoloc_ptr.php", data=route)
    print(r.status_code, r.reason)

    if r.status_code == 201 and json_validator(r.text):
      returned_json = json.loads(r.text)
      # unicode
      print(returned_json[u'request_id'])
      outfile.write(str(returned_json[u'request_id'])+', '+str(r.status_code)+', '+str(r.reason)+'\n')
    else:
      outfile.write('Problem with file '+str(filename)+'. Returned '+str(r.status_code)+', '+str(r.reason)+'\n')

