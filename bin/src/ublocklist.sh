#!/bin/bash
sedcmd=${SEDCMD:-sed}
NAME_280=($(date "+%Y%m"))
timestamp=$(date "+%Y%m%d-%H")

#adblock/bin/src
script_dir=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
#filename.sh
script_name=$(basename ${BASH_SOURCE[0]})
#filename
base_name=${script_name%.*}

#adblock/bin
bin_dir=$(dirname ${script_dir})
#adblock
base_dir=$(dirname ${bin_dir})

#adblock/tmp/filename
tmp_dir="$base_dir/tmp/$base_name"
#adblock/doc/filename
myrule_dir="$base_dir/doc/$base_name"

#working dir
work_dir=()

download(){

    rm -rf $tmp_dir
    while read line;
    do
	local import_name=($(eval echo $line))
	echo -e "\n${import_name[@]}"
	if [ "${import_name[0]}" != "" ]; then
	    if [ ! -d "$tmp_dir/${import_name[0]}" ]; then
		echo "make $tmp_dir/${import_name[0]}"
		mkdir -p $tmp_dir/${import_name[0]}
		work_dir=("${work_dir[@]}" ${import_name[0]})
	    fi

	    curl -L ${import_name[2]} | awk 1 > "$tmp_dir/${import_name[0]}/${import_name[1]}"
	    nkf -Lu --overwrite "$tmp_dir/${import_name[0]}/${import_name[1]}"

	    if [ ! -s "$tmp_dir/${import_name[0]}/${import_name[1]}" ]; then
		echo "0byte"
		rm "$tmp_dir/${import_name[0]}/${import_name[1]}"
	    else
		echo "OK"
	    fi
	fi
    done < $script_dir/$base_name.txt

}

copy_myrule(){

    echo "Copy_myrule"
    cp -RT "$myrule_dir" "$tmp_dir"
}

merge_ublocklist(){

    local tmp_dir_local="$tmp_dir/ublocklist"
    for f in $tmp_dir_local/*.txt
    do
	cat $f | sed -e "/^\s/d" | sed -e "/^!/d" | sed -e "/^$/d" >> "$tmp_dir_local/ublocklist.conf"
    done

    cp  "$tmp_dir_local/ublocklist.conf" "$base_dir/ublocklist.txt"
    sed -i "1i\!$timestamp" $base_dir/ublocklist.txt
}

change_adblock2privoxy(){
    adblock2privoxy -t $script_dir/ublocklist.task
}

main(){
    download
    copy_myrule
    merge_ublocklist
    change_adblock2privoxy
    exit 0
}

main
