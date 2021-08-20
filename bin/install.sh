#!/bin/bash

sedcmd=${SEDCMD:-sed}
NAME_280=($(date -d '1 month' "+%Y%m"))
echo $NAME_280

#FILE_NAME, FILE_DIR
download_list(){

    local i=0
    while [ "${UBLOCK_URL[i]}" != "" ]
    do
	curl -L ${UBLOCK_URL[i]} > $UBLOCKLIST_DIR/${UBLOCK_NAME[i]}
	nkf -Lu --overwrite $UBLOCKLIST_DIR/${UBLOCK_NAME[i]}
	let i++
    done
    
    local i=0
    while [ "${DNS_URL[i]}" != "" ]
    do
	curl -L ${DNS_URL[i]} > $DNSLIST_DIR/${DNS_NAME[i]}
	nkf -Lu --overwrite $DNSLIST_DIR/${DNS_NAME[i]}
	let i++
    done
    
    local i=0
    while [ "${BLACK_URL[i]}" != "" ]
    do
	curl -L ${BLACK_URL[i]} > $UBLACKLIST_DIR/${BLACK_NAME[i]}
	nkf -Lu --overwrite $UBLACKLIST_DIR/${BLACK_NAME[i]}
	let i++
    done
    
}


url_blocklist(){
    
    #280blocker
    UBLOCK_URL[0]="https://280blocker.net/files/280blocker_adblock_$NAME_280.txt"
    UBLOCK_NAME[0]="280blocker_adblock.txt"
    
    UBLOCK_URL[1]="https://raw.githubusercontent.com/Yuki2718/adblock/master/japanese/jp-filters.txt"
    UBLOCK_NAME[1]="yuki_jpfilter.txt"

    UBLOCK_URL[2]="https://raw.githubusercontent.com/tofukko/filter/master/Adblock_Plus_list.txt"
    UBLOCK_NAME[2]="tofukko_filter.txt"
}

url_dnslist(){

    #280blocker
    DNS_URL[0]="https://280blocker.net/files/280blocker_domain_$NAME_280.txt"
    DNS_NAME[0]="280blocker_domain.txt"

    DNS_URL[1]="https://pgl.yoyo.org/adservers/serverlist.php?hostformat=showintro=0&mimetype=plaintext"
    DNS_NAME[1]="pgl_yoyo.txt"
    
}

url_ublacklist(){

    BLACK_URL[0]="https://raw.githubusercontent.com/ncaq/uBlacklistRule/master/uBlacklist.txt"
    BLACK_NAME[0]="ncaq.txt"
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
    
    ADBLOCK_MERGE="$UBLOCKLIST_DIR/ad-block_merge.conf"
    ADBLOCK_SORT="$UBLOCKLIST_DIR/ad-block_sort.conf"
    
    BLOCK_DNS_LIST="$DIR/uBlockdns.txt"
    BLOCK_DNSMASQ_LIST="$DNSMASQ_DIR/ad-block.conf"
    BLOCK_FILTER_MERGE="$UBLOCKLIST_DIR/filter_merge.txt"
    BLOCK_FILTER_LIST="$DIR/uBlockOrigin.txt"

    UBLACK_MERGE="$UBLACKLIST_DIR/uBlacklist_tmp.txt"
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
    
    local i=0
    local FILE_LIST=($(ls $UBLACKLIST_DIR/*.txt))
    while [ "${FILE_LIST[i]}" != "" ]
    do
	echo "${FILE_LIST[i]}"
	cat ${FILE_LIST[i]}  >> $UBLACK_MERGE
	let i++
    done

    nkf -Lu $UBLACK_MERGE | sort | uniq > $UBLACK_SORT
}

merge_block_list(){

    echo  " "
    echo "merge ublocklist"
    
    local i=0
    local FILE_LIST=($(ls $UBLOCKLIST_DIR/*.txt))
    while [ "${FILE_LIST[i]}" != "" ]
    do
	echo "${FILE_LIST[i]}"
	cat ${FILE_LIST[i]}  >> $BLOCK_FILTER_MERGE
	let i++
    done

    nkf -Lu --overwrite $BLOCK_FILTER_MERGE
    sed '/^!/d' $BLOCK_FILTER_MERGE > $BLOCK_FILTER_LIST

    rm $BLOCK_FILTER_MERGE
}

make_privoxy_list(){
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
    local i=0
    local FILE_LIST=($(ls $DNSLIST_DIR/*.txt))
    while [ "${FILE_LIST[i]}" != "" ]
    do
	cat ${FILE_LIST[i]} | sort | grep -v '^@' | grep -v '^|' | sed -e '1s/^\xef\xbb\xbf//' | sed -e "s/\r//g" | sed -e "/^#/d"|sed -e "/^[<space><tab>\n\r]*$/d"|sed -e "/^$/d" >> $ADBLOCK_MERGE
	let i++
    done
    
    nkf -Lu $ADBLOCK_MERGE | sort | uniq > $ADBLOCK_SORT
    
    COUNT=($(cat $ADBLOCK_SORT | wc -l))
    echo "... SORT and MERGE... $COUNT"
    
    cat $ADBLOCK_SORT | sed -e "s/^/address=\//g" | sed -e "s/\$/\/0\.0\.0\.0/g" > $BLOCK_DNSMASQ_LIST
    cat $ADBLOCK_SORT | sed -e "s/^/\|\|/g" | sed -e "s/\$/^/g" > $BLOCK_DNS_LIST

}

main(){

    adblock_init

    url_blocklist
    url_dnslist
    url_ublacklist
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
