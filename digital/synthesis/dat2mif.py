#!/bin/python2.7

import sys

width_data = 32
width_adr = 2**11
name_file = sys.argv[1]

print "WIDTH = %d;" % width_data
print "DEPTH = %d;" % width_adr
print "ADDRESS_RADIX = HEX;"
print "DATA_RADIX = HEX;"
print "CONTENT BEGIN"

afile = open(name_file, "r")

i = 0
for line in afile:
  print ("%08x" % i) + ': ' + line[0:len(line) - 1] + ';\n',
  i += 1

for j in range(i, width_adr):
  print ("%08x" % j) + ': 00000000;'

print "END"
