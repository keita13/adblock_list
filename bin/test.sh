#!/bin/bash

NAME_280=202109

while read line;
do
    
    NAME=($(eval echo $line))
echo ${NAME[2]}
done < download_list.txt
