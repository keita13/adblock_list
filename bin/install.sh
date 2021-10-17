#!/bin/bash

script_dir=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
base_dir=$(dirname ${script_dir})

main(){

    bash "$script_dir/src/dnsfilter.sh"
    bash "$script_dir/src/ublacklist.sh"
    bash "$script_dir/src/ublocklist.sh"

    git add $base_dir
    git commit -m "$(date "+%Y%m%d")"
    git push origin master
    exit 0
}


main
