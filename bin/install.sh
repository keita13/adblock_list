#!/bin/bash

sedcmd=${SEDCMD:-sed}
NAME_280=($(date -d '1 month' "+%Y%m"))
echo $NAME_280

#FILE_DIR FILE_NAME FILE_URL
download_list(){

    while read line;
    do
    
	local IMPORT_NAME=($(eval echo $line))
	echo ${IMPORT_NAME[@]}
	curl -L ${IMPORT_NAME[2]} > $DIR_TMP/${IMPORT_NAME[0]}/${IMPORT_NAME[1]}
	nkf -Lu --overwrite $DIR_TMP/${IMPORT_NAME[0]}/${IMPORT_NAME[1]}
	
    done < $DIR/bin/download_list.txt
    
}

adblock_init(){

    DIR="$HOME/adblock_list"
    DIR_TMP="$DIR/tmp"
    RULE_DIR="$DIR/doc"
    
    echo "Delte tmp file"
    rm -rf $DIR_TMP/*
    echo "Copy myrule"
    cp -RT "$RULE_DIR" "$DIR_TMP"
    
    DNSLIST_DIR="$DIR_TMP/dnslist"
    UBLOCKLIST_DIR="$DIR_TMP/uBlocklist"
    UBLACKLIST_DIR="$DIR_TMP/uBlacklist"

    PRIVOXY_DIR="$DIR/etc/privoxy"
    DNSMASQ_DIR="$DIR/etc/dnsmasq.blocklist.d"
    
    ADBLOCK_SORT="$UBLOCKLIST_DIR/ad-block_sort.conf"
    
    BLOCK_DNS_LIST="$DIR/uBlockdns.txt"
    BLOCK_DNSMASQ_LIST="$DNSMASQ_DIR/ad-block.conf"
    BLOCK_FILTER_LIST="$DIR/uBlockOrigin.txt"

    UBLACK_SORT="$DIR/uBlacklist.txt"
    
    if [ ! -d "$UBLOCKLIST_DIR" ]; then
        mkdir $UBLOCKLIST_DIR
    fi
    if [ ! -d "$DNSLIST_DIR" ]; then
        mkdir $DNSLIST_DIR
    fi
    if [ ! -d "$UBLACKLIST_DIR" ]; then
        mkdir $UBLACKLIST_DIR
    fi
    if [ ! -d "$PRIVOXY_DIR" ]; then
        mkdir $PRIVOXY_DIR
    fi
    if [ ! -d "$DNSMASQ_DIR" ]; then
        mkdir $DNSMASQ_DIR
    fi

}

merge_ublack_list(){

    echo "Merge uBlacklist"
    local i=0
    local FILE_LIST=($(ls $UBLACKLIST_DIR/*.txt))
    while [ "${FILE_LIST[i]}" != "" ]
    do
	echo "${FILE_LIST[i]}"
	cat ${FILE_LIST[i]}  >> $UBLACK_SORT
	
	let i++
    done

    sort -u $UBLACK_SORT -o $UBLACK_SORT | uniq
}

merge_block_list(){

    echo "Merge uBlocklist"
    
    local i=0
    local FILE_LIST=($(ls $UBLOCKLIST_DIR/*.txt))
    while [ "${FILE_LIST[i]}" != "" ]
    do
	echo "${FILE_LIST[i]}"
	cat ${FILE_LIST[i]} | sed '^!/d' >> $BLOCK_FILTER_LIST
	let i++
    done

}

make_privoxy_list(){

    echo "Make Privoxy list"
    local i=0
    local FILE_LIST=($(ls $UBLOCKLIST_DIR/*.txt))
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

make_dns_list(){

    echo "Make Dns list"
    local i=0
    local FILE_LIST=($(ls $DNSLIST_DIR/*.txt))
    while [ "${FILE_LIST[i]}" != "" ]
    do
	cat ${FILE_LIST[i]} | sort | grep -v '^@' | grep -v '^|' | sed -e '1s/^\xef\xbb\xbf//' | sed -e "s/\r//g" | sed -e "/^#/d"|sed -e "/^[<space><tab>\n\r]*$/d"|sed -e "/^$/d" >> $ADBLOCK_SORT
	let i++
    done
    
    sort -u $ADBLOCK_SORT -o $ADBLOCK_SORT | uniq
    
    COUNT=($(cat $ADBLOCK_SORT | wc -l))
    echo "... SORT and MERGE... $COUNT"
    
    cat $ADBLOCK_SORT | sed -e "s/^/address=\//g" | sed -e "s/\$/\/0\.0\.0\.0/g" > $BLOCK_DNSMASQ_LIST
    cat $ADBLOCK_SORT | sed -e "s/^/\|\|/g" | sed -e "s/\$/^/g" > $BLOCK_DNS_LIST

}

main(){

    adblock_init
    download_list

    make_privoxy_list
    make_dns_list
    merge_block_list
    merge_ublack_list
    
    git add .
    git commit -m "$(date "+%Y%m%d")"
    git push origin master
    echo "End"
    exit 0
}

main
