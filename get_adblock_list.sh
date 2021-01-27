#!/bin/bash

sedcmd=${SEDCMD:-sed}
NAME_280=($(date -d '1 month' "+%Y%m"))
echo $NAME_280

url_list_AdblockPlus(){
    
    #280blocker
    URL_NAME_AdblockPlus[0]="https://280blocker.net/files/280blocker_adblock_$NAME_280.txt"
    FILE_NAME_AdblockPlus[0]="280blocker_adblock.txt"
    
    URL_NAME_AdblockPlus[1]="https://raw.githubusercontent.com/Yuki2718/adblock/master/japanese/jp-filters.txt"
    FILE_NAME_AdblockPlus[1]="yuki_jpfilter.txt"

    URL_NAME_AdblockPlus[2]="https://raw.githubusercontent.com/tofukko/filter/master/Adblock_Plus_list.txt"
    FILE_NAME_AdblockPlus[2]="tofukko_filter.txt"
}

url_list_adblock_dns(){
    
    #280blocker
    URL_NAME_DNS[0]="https://280blocker.net/files/280blocker_domain_$NAME_280.txt"
    FILE_NAME_DNS[0]="280blocker_domain.txt"
    
    URL_NAME_DNS[1]="https://280blocker.net/files/280blocker_domain_ag_$NAME_280.txt"
    FILE_NAME_DNS[1]="280blocker_domain_ag.txt"

    URL_NAME_DNS[2]="https://pgl.yoyo.org/adservers/serverlist.php?hostformat=showintro=0&mimetype=plaintext"
    FILE_NAME_DNS[2]="pgl_yoyo.txt"
}

work_dir(){
    
    DIR="$(pwd)"
    AdblockPlus_TXT_DIR="$DIR/AdGuard/AdblockPlus"
    DNS_TXT_DIR="$DIR/AdGuard/dns"
    
    PRIVOXY_DIR="$DIR/privoxy"
    DNSMASQ_DIR="$DIR/dnsmasq"
    
    ADBLOCK_MERGE="$DNSMASQ_DIR/ad-block_merge.conf"
    ADBLOCK_SORT="$DNSMASQ_DIR/ad-block_sort.conf"
    ADBLOCK_LIST="$DNSMASQ_DIR/ad-block.conf"
    
    if [ ! -d "$AdblockPlus_TXT_DIR" ]; then
        mkdir $AdblockPlus_TXT_DIR
    fi
    if [ ! -d "$DNS_TXT_DIR" ]; then
        mkdir $DNS_TXT_DIR
    fi
    if [ ! -d "$PRIVOXY_DIR" ]; then
        mkdir $PRIVOXY_DIR
    fi
    if [ ! -d "$DNSMASQ_DIR" ]; then
        mkdir $DNS_TXT_DIR
    fi

}

download_list(){
    i=0
    while [ "${URL_NAME_AdblockPlus[i]}" != "" ]
    do
	curl -L ${URL_NAME_AdblockPlus[i]} > $AdblockPlus_TXT_DIR/${FILE_NAME_AdblockPlus[i]}
	let i++
    done

    i=0
    while [ "${URL_NAME_DNS[i]}" != "" ]
    do  
	curl -L ${URL_NAME_DNS[i]} > $DNS_TXT_DIR/${FILE_NAME_DNS[i]}
	let i++
    done

}

make_privoxy_list(){
    i=0
    FILE_LIST=($(ls $AdblockPlus_TXT_DIR/*.txt))
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
	
	actionfiledest="${PRIVOXY_DIR}/$(basename ${actionfile})"
	echo "... copying ${actionfile} to ${actionfiledest}"
	mv "${actionfile}" "${actionfiledest}"
	filterfiledest="${PRIVOXY_DIR}/$(basename ${filterfile})"
	echo "... copying ${filterfile} to ${filterfiledest}"
	mv "${filterfile}" "${filterfiledest}"
	
	let i++
    done

}

make_adblock_list(){
    i=0
    rm $ADBLOCK_LIST
    FILE_LIST=($(ls $DNS_TXT_DIR/*.txt))
    while [ "${FILE_LIST[i]}" != "" ]
    do
	cat ${FILE_LIST[i]} | sort | grep -v '^@' | grep -v '^|' | sed -e '1s/^\xef\xbb\xbf//' | sed -e "s/\r//g" | sed -e "/^#/d"|sed -e "/^[<space><tab>\n\r]*$/d"|sed -e "/^$/d" >> $ADBLOCK_MERGE
	let i++
    done

    cat $ADBLOCK_MERGE | sort |  sed -e "s/^/address=\//g" | sed -e "s/\$/\/0\.0\.0\.0/g" > $ADBLOCK_SORT
    
    COUNT=($(cat $ADBLOCK_SORT | wc -l))
    echo "...SORT and MERGE.. $COUNT"
    while read line
    do
	if [ $(cat $ADBLOCK_SORT | tail -n $COUNT | grep -c "$line") == 1 ]; then
            echo $line >> $ADBLOCK_LIST
	fi
	let COUNT--
    done < $ADBLOCK_SORT

    rm $ADBLOCK_MERGE $ADBLOCK_SORT 
    
}

main(){

    work_dir
    url_list_AdblockPlus
    url_list_adblock_dns
    download_list
    make_privoxy_list
    make_adblock_list
}

main
