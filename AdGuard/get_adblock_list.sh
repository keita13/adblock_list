#!/bin/bash

sedcmd=${SEDCMD:-sed}


adblock_url_list(){
    
    NAME_280=($(date -d '1 month' "+%Y%m"))
    echo $NAME_280
    #280blocker
    URL_NAME[0]="https://280blocker.net/files/280blocker_adblock_$NAME_280.txt"
    FILE_NAME[0]="280blocker_adblock.txt"
    
    URL_NAME[1]="https://raw.githubusercontent.com/Yuki2718/adblock/master/japanese/jp-filters.txt"
    FILE_NAME[1]="yuki_jpfilter.txt"

    URL_NAME[2]="https://raw.githubusercontent.com/tofukko/filter/master/Adblock_Plus_list.txt"
    FILE_NAME[2]="tofukko_filter.txt"
}

work_dir(){
    
    TXT_DIR="$(pwd)/txt"
    privoxydir="$(pwd)"

    if [ ! -d "$TXT_DIR" ]; then
        mkdir $TXT_DIR
    fi

}

download_adlist(){
    i=0
    while [ "${URL_NAME[i]}" != "" ]
    do
	curl -L ${URL_NAME[i]} > $TXT_DIR/${FILE_NAME[i]}
	let i++
    done

}

make_adblock_list(){
    i=0
    FILE_LIST=($(ls $TXT_DIR/*.txt))
    while [ "${FILE_LIST[i]}" != "" ]
    do
	echo "${FILE_LIST[i]}"
	file="${FILE_LIST[i]}"
	actionfile=${file%\.*}.script.action
	filterfile=${file%\.*}.script.filter
	list=$(basename ${file%\.*})

	#[ "$(grep -E '^.*\[Adblock.*\].*$' ${file})" == "" ] && echo "The list recieved from ${url} isn't an AdblockPlus list. Skipped" && continue

	echo "Creating actionfile for ${list} ..."
	echo -e "{ +block{${list}} }" > ${actionfile}
	$sedcmd '/^!.*/d;1,1 d;/^@@.*/d;/\$.*/d;/#/d;s/\./\\./g;s/\?/\\?/g;s/\*/.*/g;s/(/\\(/g;s/)/\\)/g;s/\[/\\[/g;s/\]/\\]/g;s/\^/[\/\&:\?=_]/g;s/^||/\./g;s/^|/^/g;s/|$/\$/g;/|/d' ${file} >> ${actionfile}
	
	
	echo "... creating filterfile for ${list} ..."
	echo "FILTER: ${list} Tag filter of ${list}" > ${filterfile}
	$sedcmd '/^#/!d;s/^##//g;s/^#\(.*\)\[.*\]\[.*\]*/s@<([a-zA-Z0-9]+)\\s+.*id=.?\1.*>.*<\/\\1>@@g/g;s/^#\(.*\)/s@<([a-zA-Z0-9]+)\\s+.*id=.?\1.*>.*<\/\\1>@@g/g;s/^\.\(.*\)/s@<([a-zA-Z0-9]+)\\s+.*class=.?\1.*>.*<\/\\1>@@g/g;s/^a\[\(.*\)\]/s@<a.*\1.*>.*<\/a>@@g/g;s/^\([a-zA-Z0-9]*\)\.\(.*\)\[.*\]\[.*\]*/s@<\1.*class=.?\2.*>.*<\/\1>@@g/g;s/^\([a-zA-Z0-9]*\)#\(.*\):.*[:[^:]]*[^:]*/s@<\1.*id=.?\2.*>.*<\/\1>@@g/g;s/^\([a-zA-Z0-9]*\)#\(.*\)/s@<\1.*id=.?\2.*>.*<\/\1>@@g/g;s/^\[\([a-zA-Z]*\).=\(.*\)\]/s@\1^=\2>@@g/g;s/\^/[\/\&:\?=_]/g;s/\.\([a-zA-Z0-9]\)/\\.\1/g' ${file} >> ${filterfile}
	echo "... filterfile created - adding filterfile to actionfile ..."
	echo "{ +filter{${list}} }" >> ${actionfile}
	echo "*" >> ${actionfile}
	echo "... filterfile added ..."
	
	echo "... creating and adding whitlist for urls ..."
	echo "{ -block }" >> ${actionfile}
	$sedcmd '/^@@.*/!d;s/^@@//g;/\$.*/d;/#/d;s/\./\\./g;s/\?/\\?/g;s/\*/.*/g;s/(/\\(/g;s/)/\\)/g;s/\[/\\[/g;s/\]/\\]/g;s/\^/[\/\&:\?=_]/g;s/^||/\./g;s/^|/^/g;s/|$/\$/g;/|/d' ${file} >> ${actionfile}
	echo "... created and added whitelist - creating and adding image handler ..."
	
	echo "{ -block +handle-as-image }" >> ${actionfile}
	$sedcmd '/^@@.*/!d;s/^@@//g;/\$.*image.*/!d;s/\$.*image.*//g;/#/d;s/\./\\./g;s/\?/\\?/g;s/\*/.*/g;s/(/\\(/g;s/)/\\)/g;s/\[/\\[/g;s/\]/\\]/g;s/\^/[\/\&:\?=_]/g;s/^||/\./g;s/^|/^/g;s/|$/\$/g;/|/d' ${file} >> ${actionfile}
	echo "... created and added image handler ..."
	echo "... created actionfile for ${list}."
	
	actionfiledest="${privoxydir}/$(basename ${actionfile})"
	echo "... copying ${actionfile} to ${actionfiledest}"
	mv "${actionfile}" "${actionfiledest}"
	filterfiledest="${privoxydir}/$(basename ${filterfile})"
	echo "... copying ${filterfile} to ${filterfiledest}"
	mv "${filterfile}" "${filterfiledest}"
	
	let i++
    done

}


main(){

    work_dir
    adblock_url_list
    #download_adlist
    make_adblock_list
}

main
