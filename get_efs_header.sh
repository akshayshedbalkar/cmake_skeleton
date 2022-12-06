#!/bin/bash
# Author: Shedbalkar, Akshay (GH2)

read -p "Enter KITT username: " uname
read -s -p "Enter KITT password: " pw
HEADER=$(curl -su $uname:$pw https://kitt.efs-techhub.com/display/AT00639/Datei-Header | grep -P -A 8 -m 1 "\/\*\*"|sed 's/.*\(\/\*\*\)/\1/'|sed 's/\(\*\/\).*/\1/')

echo "$HEADER" > efs_header.h
