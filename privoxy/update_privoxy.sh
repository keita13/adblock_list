#!/bin/bash

FILE=($(ls | grep -e .script.action -e .script.filter))
i=0
while [ "${FILE[i]}" != "" ]
do
  echo ${FILE[i]}
  sudo cp ${FILE[i]} /etc/privoxy/${FILE[i]}
  let i++
done

sudo sh -c "/etc/privoxy/privoxy-blocklist.sh"

sudo systemctl restart privoxy.service
