#!/bin/bash

sedcmd=${SEDCMD:-sed}

#adblock/bin/src
script_dir=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
#adblock/bin
bin_dir=$(dirname ${script_dir})
#adblock
base_dir=$(dirname ${bin_dir})

main(){

    #rm -rf $base_dir/tmp

    for f in $script_dir/*.txt;
    do
	echo $f
	dir=$(cat $f | awk '{ print $1 }')
	echo "$dir"
	if [ ! -d "$base_dir/tmp/$dir" ]; then
	    echo $base_dir/tmp/$dir
	    echo "make"
	fi
    done

}

main
