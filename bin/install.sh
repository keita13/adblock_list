#!/bin/bash

sedcmd=${SEDCMD:-sed}
NAME_280=($(date -d '1 month' "+%Y%m"))
echo $NAME_280

url_blocklist(){

    #280blocker
    Filter_URL[0]="https://280blocker.net/files/280blocker_adblock_$NAME_280.txt"
    Filter_NAME[0]="280blocker_adblock.txt"

    Filter_URL[1]="https://raw.githubusercontent.com/Yuki2718/adblock/master/japanese/jp-filters.txt"
    Filter_NAME[1]="yuki_jpfilter.txt"

    Filter_URL[2]="https://raw.githubusercontent.com/tofukko/filter/master/Adblock_Plus_list.txt"
    Filter_NAME[2]="tofukko_filter.txt"
}

url_dnslist(){

    #280blocker
    DNS_URL[0]="https://280blocker.net/files/280blocker_domain_$NAME_280.txt"
    DNS_NAME[0]="280blocker_domain.txt"

    DNS_URL[1]="https://pgl.yoyo.org/adservers/serverlist.php?hostformat=showintro=0&mimetype=plaintext"
    DNS_NAME[1]="pgl_yoyo.txt"
    
}

copy_myrule(){

    RULE_DIR="$HOME/doc"
    cp -r "$RULE_DIR" "$DIR/tmp"
    echo "Copy myrule"

}

work_dir(){

    DIR="$HOME/adblock_list"
    BLOCK_TXT_DIR="$DIR/tmp/uBlocklist"
    DNS_TXT_DIR="$DIR/tmp/dnslist"

    PRIVOXY_DIR="$DIR/etc/privoxy"
    DNSMASQ_DIR="$DIR/etc/dnsmasq.blocklist.d"
    
    ADBLOCK_MERGE="$BLOCK_TXT_DIR/ad-block_merge.conf"
    ADBLOCK_SORT="$BLOCK_TXT_DIR/ad-block_sort.conf"
    BLOCK_DNS_LIST="$DIR/uBlockdns.txt"
    BLOCK_DNSMASQ_LIST="$DNSMASQ_DIR/ad-block.conf"
    BLOCK_FILTER_MERGE="$DNS_TXT_DIR/filter_merge.txt"
    BLOCK_FILTER_LIST="$DIR/uBlockOrigin.txt"
    
    if [ ! -d "$BLOCK_TXT_DIR" ]; then
        mkdir $BLOCK_TXT_DIR
    fi
    if [ ! -d "$DNS_TXT_DIR" ]; then
        mkdir $DNS_TXT_DIR
    fi
    if [ ! -d "$PRIVOXY_DIR" ]; then
        mkdir $PRIVOXY_DIR
    fi
    if [ ! -d "$DNSMASQ_DIR" ]; then
        mkdir $DNSMASQ_TXT_DIR
    fi

    rm $ADBLOCK_MERGE $ADBLOCK_LIST $BLOCK_DNS_LIST $BLOCK_FILTER_MERGE

}

download_list(){
    i=0
    while [ "${Filter_URL[i]}" != "" ]
    do
	curl -L ${Filter_URL[i]} > $BLOCK_TXT_DIR/${Filter_NAME[i]}
	let i++
    done

    i=0
    while [ "${DNS_URL[i]}" != "" ]
    do
	curl -L ${DNS_URL[i]} > $DNS_TXT_DIR/${DNS_NAME[i]}
	let i++
    done

}


merge_block_list(){
    i=0
    local FILE_LIST=($(ls $BLOCK_TXT_DIR/*.txt))
    while [ "${FILE_LIST[i]}" != "" ]
    do
	echo "${FILE_LIST[i]}"
	cat ${FILE_LIST[i]}  >> $BLOCK_FILTER_MERGE
	let i++
    done
    mv $BLOCK_FILTER_MERGE $BLOCK_FILTER_LIST
}

make_privoxy_list(){
    i=0
    local FILE_LIST=($(ls $BLOCK_TXT_DIR/*.txt))
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
    i=0
    local FILE_LIST=($(ls $DNS_TXT_DIR/*.txt))
    while [ "${FILE_LIST[i]}" != "" ]
    do
	cat ${FILE_LIST[i]} | sort | grep -v '^@' | grep -v '^|' | sed -e '1s/^\xef\xbb\xbf//' | sed -e "s/\r//g" | sed -e "/^#/d"|sed -e "/^[<space><tab>\n\r]*$/d"|sed -e "/^$/d" >> $ADBLOCK_MERGE
	let i++
    done

    #cat $ADBLOCK_MERGE | sort |  sed -e "s/^/address=\//g" | sed -e "s/\$/\/0\.0\.0\.0/g" > $ADBLOCK_SORT
    cat $ADBLOCK_MERGE | sort > $ADBLOCK_SORT

    COUNT=($(cat $ADBLOCK_SORT | wc -l))
    echo "... SORT and MERGE... $COUNT"
    while read line
    do
	if [ $(cat $ADBLOCK_SORT | tail -n $COUNT | grep -c "$line") == 1 ]; then
            #echo $line >> $ADBLOCK_LIST
            echo $line | sed -e "s/^/address=\//g" | sed -e "s/\$/\/0\.0\.0\.0/g" >> $BLOCK_DNSMASQ_LIST
            echo $line | sed -e "s/^/\|\|/g" | sed -e "s/\$/^/g" >> $BLOCK_DNS_LIST
            echo -n "."
	fi
	let COUNT--
    done < $ADBLOCK_SORT

    rm $ADBLOCK_MERGE $ADBLOCK_SORT

}

main(){

    work_dir
    copy_myrule
    url_blocklist
    url_dnslist
    #download_list
    make_privoxy_list
    make_dns_list
    merge_block_list
    
    git add .
    git commit -m "$(date "+%Y%m%d")"
    git push origin master
    echo "End"
    exit 0
}

main
