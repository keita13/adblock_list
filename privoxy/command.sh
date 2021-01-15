#!/bin/bash

adblock_url_list(){
    
    NAME_280=($(date -d '1 month' "+%Y%m"))
    #280blocker
    URL_NAME[0]="https://280blocker.net/files/280blocker_adblock_$NAME_280.txt"
    URL_NAME[1]="https://raw.githubusercontent.com/tofukko/filter/master/Adblock_Plus_list.txt"
    URL_NAME[2]="https://raw.githubusercontent.com/k2jp/abp-japanese-filters/master/abpjf.txt"

}

download_adlist(){
cd /etc/privoxy/
    i=0
    while [ "${URL_NAME[i]}" != "" ]
    do  
	sudo sh -c "bash privoxy-adblock.sh -p /etc/privoxy -u "${URL_NAME[i]}""
	let i++
    done
    
}


main(){
sudo sh -c "/etc/privoxy/privoxy-blocklist.sh"
adblock_url_list
download_adlist

}

main
