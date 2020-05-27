#Mikroik Probe version 0.1a

/interface pwr-line
set [ find default-name=pwr-line1 ] disabled=yes
/interface ethernet
set [ find default-name=ether1 ] advertise=10M-full
set [ find default-name=ether2 ] disabled=yes
set [ find default-name=ether3 ] disabled=yes
/interface list
add name=WAN
/ip firewall connection tracking
set enabled=no
/ip neighbor discovery-settings
set discover-interface-list=WAN
/ip settings
set ip-forward=no tcp-syncookies=yes
/interface list member
add interface=ether1 list=WAN
/ip dhcp-client
add disabled=no interface=ether1
/ip firewall address-list
add address=xxxxxxxxxx.sn.mynetname.net list=PROBE
add address=127.0.0.0/24 list=HIVE
add address=127.0.0.2 list=STATIC
/ip firewall filter
add action=accept chain=input src-address-list=PROBE
add action=accept chain=input src-address-list=HIVE
add action=accept chain=input protocol=udp src-address=1.1.1.2 src-port=53
add action=accept chain=input protocol=udp src-address=1.0.0.2 src-port=53
add action=accept chain=input icmp-options=0:0-255 protocol=icmp
add action=accept chain=input protocol=udp src-port=123
add action=drop chain=input
/ip firewall service-port
set ftp disabled=yes
set tftp disabled=yes
set irc disabled=yes
set h323 disabled=yes
set sip disabled=yes
set pptp disabled=yes
set udplite disabled=yes
set dccp disabled=yes
set sctp disabled=yes
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/ip ssh
set strong-crypto=yes
/system identity
set name=MT-Probe
/system leds
add leds=user-led type=on
/system ntp client
set enabled=yes server-dns-names=pool.ntp.org
/system scheduler
add name=mtprobe-prime on-event=":global hivehost 172.29.40.50;" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
add interval=1m name=mtprobe-checkin on-event=mtprobe-checkin policy=\
    read,write,policy,test start-time=startup
add interval=1m name=mtprobe-phone-home on-event=mtprobe-phone-home policy=\
    read,write,policy,test start-time=startup
add interval=30m name=mtprobe-ping-bwtest on-event=\
    "mtprobe-check-hosts-status\r\
    \nmtprobe-ping-bwtest" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
/tool netwatch
add down-script="/system leds set type=off [find leds=user-led]" host=1.1.1.1 \
    up-script="/system leds set type=on [find leds=user-led]"

