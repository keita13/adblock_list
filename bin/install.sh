#!/bin/bash

script_dir=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
base_dir=$(dirname ${script_dir})

main(){

    cd $base_dir
    git pull origin master

    bash "$script_dir/src/dnsfilter.sh"
    bash "$script_dir/src/ublacklist.sh"
    bash "$script_dir/src/ublocklist.sh"

    cd $base_dir
    git add .
    git commit -m "$(date "+%Y%m%d")"
    git push origin master
    exit 0
}


main
