#!/bin/bash
sudo cp ad-block.conf /etc/dnsmasq.blocklist.d/ad-block.conf
sudo systemctl restart dnsmasq.service
