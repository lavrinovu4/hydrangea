#!/bin/env python2.7

import re
import sys

def search_port_definition(line, text):
  # search:  "<item_searched> name"
  #          " <item_searched> name1, name2"
  #          " <item_searched> [<d> : <d>] name"
  #          " <item_searched> [<d>:<d>] name"
  # print text
  m = re.match("\s*" + text + "\s+((?P<size>[[]\d*\s*:\s*\d*[]])\s+)?(?P<name>(\w(, )?)+)", line)

  if m:
    dict_ = m.groupdict()
    dict_n = {"name": dict_["name"], "size": dict_["size"]}
    return dict_n

  return None

def search_inst(line, text):
  m = re.match("(?P<module>\w+) \w+( |)\(\s*\/\*"+text+"\*\/\s*\);", line);

  if m:
    dict_ = m.groupdict()
    dict_n = {"module": dict_["module"]}

    return dict_n

  return None

def search_by_line(file_src, list_searched, func_pattern_search):
  list_port = {}
  position = 0

  file_descriptor = open(file_src, "r");

  for line in file_descriptor:
    for item_searched in list_searched:

      finded = func_pattern_search(line, item_searched)

      if finded:
        finded['position'] = position + line.find(item_searched) + len(item_searched)

        if item_searched in list_port:
          list_port[item_searched].append(finded)
        else:
          list_port[item_searched] = [finded]

        position += len(line)

        break

      position += len(line)

  file_descriptor.close()

  return list_port


def print_arg(port_dict):

  return port_dict['name'] + ", "


def print_inst(port_dict, tab):

  port_conn = re.search("(?<=(i|o)_)\w+", port_dict['name'])
  size = port_dict['size']

  if not size:
    size = ""

  space_size = 20 - len(port_dict['name'])

  return "%s.%s%s( %s%s ),\n" % (tab, port_dict['name'], " " * space_size, port_conn.group(0), size )


def print_wire(port_dict, tab):

  port_conn = re.search("(?<=(i|o)_)\w+", port_dict['name'])
  size = port_dict['size']

  if not size:
    size = ""

  space_size = 10 - len(size)

  return "\n%swire %s%s%s;  " % (tab, size, " " * space_size, port_conn.group(0))


def print_port_line(list_port, text_pre, print_item, *arg):
  res_text = ""

  for key_list_port,value_list_port in list_port.iteritems():

    if value_list_port:
      res_text += text_pre[key_list_port]

    for item in value_list_port:
      res_text += print_item(item, *arg)

  return res_text[:-2]


def print_port_lines(list_port, text_pre, line_len, tab, print_item, *arg):
  res_text = ""

  for key_list_port,value_list_port in list_port.iteritems():

    if value_list_port:
      res_text += text_pre[key_list_port] + tab

    line = ""

    for item in value_list_port:
      if len(line) > line_len:
        res_text += line
        line =  "\n" + tab

      line += print_item(item, *arg)

    res_text += line

  return res_text[:-2]

def write_verilog(file_src, text_list, position_list):
  file_descriptor = open(file_src, "r")
  file_content = file_descriptor.read()
  file_descriptor.close()

  file_descriptor = open(file_src, "w")

  prev_pos = 0

  sort = zip(*sorted(zip(position_list, text_list)))
  position_list_n = list(sort[0])
  text_list_n = list(sort[1])

  for position, text in zip(position_list_n, text_list_n):
    file_descriptor.write(file_content[prev_pos:position])
    file_descriptor.write(text)
    prev_pos = position

  file_descriptor.write(file_content[position:])
  file_descriptor.close()


def find_all_occurance(file_src, str_find):
  file_descriptor = open(file_src, "r")
  file_content = file_descriptor.read()
  file_descriptor.close()

  list_pos = []
  pos = 0

  while True:
    pos = file_content.find(str_find, pos + 1)
    if (pos == -1):
      break

    list_pos.append(pos)

  return list_pos

def get_module_name(file_name):
  module_file = file_name.split("/")
  return module_file[len(module_file) - 1].split(".")[0]


# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------

# init

# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------

text_pre =   {'output': "\n      /* output ports */\n",
              'input' : "\n      /* input ports */\n",
              'inout' : "\n      /* inout ports */\n"}

type_ports = ["output", "input", "inout"]

special_words = {"inst": "autoinst",
                  "arg": "autoarg",
                 "wire": "autowire"
                 }
# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------

# arg

# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------
file_list = sys.argv[1:]
global_port_list = {}


for item in file_list:
  global_port_list[get_module_name(item)] = search_by_line(item, type_ports, search_port_definition)

for item in file_list:
  position = find_all_occurance(item, "/*" + special_words["arg"] + "*/);")

  if position:
    list_port = global_port_list[get_module_name(item)]

    if list_port:
      port_coon = print_port_lines(list_port, text_pre, 50, " " * 6, print_arg)
      write_verilog(item, [port_coon], [position[0] + len(special_words["arg"] + "\*\/")])




# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------

# inst + wire

# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------

for item in file_list:
  position_wire = find_all_occurance(item, "/*" + special_words["wire"] + "*/")
  list_module = search_by_line(item, {special_words['inst']}, search_inst)

  if list_module:
    port_coon = []
    position_list = []

    for item_module in list_module[special_words['inst']]:
      list_port = global_port_list[item_module['module']]

      if list_port:
        position_list.append(item_module['position'] + 2)
        port_coon.append(print_port_line(list_port, text_pre, print_inst, " " * 6))

        if position_wire:
          position_list.append(position_wire[0] + len(special_words["wire"] + "\*\/"))
          port_coon.append(print_port_line({"output": list_port["output"]}, {"output": ""}, print_wire, " " * 2))

    if position_list:
      write_verilog(item, port_coon, position_list)

