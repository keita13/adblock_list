#!/bin/bash
sedcmd=${SEDCMD:-sed}

#adblock/bin/src
script_dir=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
#adblock/bin
bin_dir=$(dirname ${script_dir})
#adblock
base_dir=$(dirname ${bin_dir})

make_dir(){

    if [ ! -d "$base_dir/tmp" ]; then
	mkdir $base_dir/tmp
    fi

    rm -rf $base_dir/tmp/*

    for f in $script_dir/*.txt;
    do
	echo $f
	while read line;
	do
	    dir=$(echo $line | awk '{ print $1 }')
	    echo "$dir"
	    if [ ! -d "$base_dir/tmp/$dir" ]; then
		echo "make"
		#mkdir $base_dir/tmp/$dir
	    fi
	done < $f
    done

}

main(){
    make_dir
    exit 0
}

main
