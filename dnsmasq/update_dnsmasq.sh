#!/bin/bash
sudo cp ad-block.conf /etc/dnsmasq.blocklist.d/ad-block.conf
sudo systemctl restart dnsmasq.service
mv ad-block_dns.txt ../AdGuard/ad-block_dns.txt
