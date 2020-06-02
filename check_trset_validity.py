#!/usr/bin/env python3

import requests
from requests.exceptions import ConnectionError

infile = '/Users/colinmccann/dev/ixmaps/trsets/00:_all_trsets.trset'
outfile = open('invalid_trset_urls.txt', 'r+')

total_count = 0
invalid_count = 0
with open(infile) as f:
  for line in f:
    parsed_line = line.split("host ")
    if parsed_line[0] == '':
      total_count += 1
      url = parsed_line[1].strip("\n")
      url = url.replace("http://", '')
      url = url.replace("https://", '')
      url = "http://" + url
      try:
        request = requests.get(url, timeout=10)
      except requests.exceptions.RequestException as e:
        invalid_count += 1
        url = url.replace("http://", '')
        outfile.write(url+' is invalid\n')
        print(url+' is invalid')
      else:
        print(url+' exists')

outfile.write('\nTotal urls: '+str(total_count))
outfile.write('\nTotal invalid urls: '+str(invalid_count))