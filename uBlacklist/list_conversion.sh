#!/bin/bash

cat origin.txt | sort > list.txt
cat list.txt | sed -e "s/^/*:\/\//g" | sed -e "s/\$/\/*/g" > uBlacklist.txt
cat list.txt | sed -e "s/^/-site:/g" | tr '\n' ' '  | sed -e "s/^/https:\/\/www\.google\.co\.jp\/search?q=%s /g" | sed -e "s/\$/\\n/g" > search_url.txt
