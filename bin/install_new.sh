#!/bin/bash

script_dir=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)

main(){

    bash "$script_dir/src/dnsfilter.sh"
    bash "$script_dir/src/ublacklist.sh"
    bash "$script_dir/src/ublocklist.sh"
}


main
