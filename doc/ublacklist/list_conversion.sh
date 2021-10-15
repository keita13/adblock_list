#!/bin/bash

cat origin.txt | sort > list.txt
cat list.txt | sed -e "s/^/*:\/\/*./g" | sed -e "s/\$/\/*/g" > uBlacklist.txt
