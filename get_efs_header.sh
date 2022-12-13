#!/bin/bash
# Author: Shedbalkar, Akshay (GH2)

read -p "Enter KITT username: " uname
read -s -p "Enter KITT password: " pw

echo "Processing..."

HEADER=$(curl -su $uname:$pw https://kitt.efs-techhub.com/display/AT00639/Datei-Header | grep -P -A 8 -m 1 "\/\*\*"|sed 's/.*\(\/\*\*\)/\1/'|sed 's/\(\*\/\).*/\1/')

echo "$HEADER" > efs_header.h

# In case you want to prepend the efs_header to a file: uncomment following line and supply file name as argument
# echo -e "$HEADER\n" | cat - $1 > temp && mv temp $1

echo "...Done!"
