#!/bin/bash

adblock_url_list(){
    
    NAME_280=($(date -d '1 month' "+%Y%m"))
    echo $NAME_280
    #280blocker
    URL_NAME[0]="https://280blocker.net/files/280blocker_adblock_$NAME_280.txt"
    FILE_NAME[0]="280blocker_adblock.txt"
    
    #URL_NAME[1]="https://280blocker.net/files/280blocker_domain_ag_$NAME_280.txt"
    #FILE_NAME[1]="280blocker_domain_ag.txt"

    #URL_NAME[2]="https://pgl.yoyo.org/adservers/serverlist.php?hostformat=showintro=0&mimetype=plaintext"
    #FILE_NAME[2]="pgl_yoyo.txt"
}

work_dir(){
    
    TXT_DIR="$(pwd)/txt"
    ADBLOCK_MERGE="ad-block_merge.conf"
    ADBLOCK_DNS="ad-block_dns.txt"
    ADBLOCK_SORT="ad-block_sort.conf"
    ADBLOCK_LIST="ad-block.conf"
    

    if [ ! -d "$TXT_DIR" ]; then
        mkdir $TXT_DIR
    fi

#    if [ -e "$ADBLOCK_MERGE" ]; then
#        rm $ADBLOCK_MERGE
#    fi
#    if [ -e "$ADBLOCK_DNS" ]; then
#        rm $ADBLOCK_DNS
#    fi
#    if [ -e "$ADBLOCK_SORT" ]; then
#        rm $ADBLOCK_SORT
#    fi
#    if [ -e "$ADBLOCK_FILE" ]; then
#        rm $ADBLOCK_FILE
#    fi

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
	cat ${FILE_LIST[i]} | sort | grep -v '^@' | grep -v '^|' | sed -e '1s/^\xef\xbb\xbf//' | sed -e "s/\r//g" | sed -e "/^#/d"|sed -e "/^[<space><tab>\n\r]*$/d"|sed -e "/^$/d" >> $ADBLOCK_MERGE
	let i++
    done

    #cat $ADBLOCK_MERGE | sort |  sed -e "s/^/address=\//g" | sed -e "s/\$/\/0\.0\.0\.0/g" > $ADBLOCK_SORT
    cat $ADBLOCK_MERGE | sort > $ADBLOCK_SORT

    COUNT=($(cat $ADBLOCK_SORT | wc -l))
    while read line
    do
	if [ $(cat $ADBLOCK_SORT | tail -n $COUNT | grep -c "$line") == 1 ]; then
	    echo $line | sed -e "s/^/address\//g" | sed -e "s/\$/\/0\.0\.0\.0/g" >> $ADBLOCK_LIST
            echo $line >> $ADBLOCK_DNS
	fi
	let COUNT--
    done < $ADBLOCK_SORT
    
}


main(){

    work_dir
    adblock_url_list
    download_adlist
    #make_adblock_list
}

main
