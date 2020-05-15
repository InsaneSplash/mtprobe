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
add name=mtprobe-prime on-event=":global hivehost 127.0.0.3;" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
add interval=5m name=mtprobe-ping-bwtest on-event=\
    mtprobe-ping-bwtest policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=may/15/2020 start-time=14:30:00
add interval=1m name=mtprobe-phone-home on-event=mtprobe-phone-home policy=\
    read,write,policy,test start-time=startup
/system script
add dont-require-permissions=no name=mtprobe-phone-home owner=admin policy=\
    read,write,policy,test source="{\r\
    \n:global hivehost;\r\
    \n\r\
    \n#Collect\r\
    \n:local serialNumber [/system routerboard get serial-number];\r\
    \n:local boardFirmware [/system routerboard get current-firmware];\r\
    \n:local boardCPU [/system resource get cpu-load];\r\
    \n:local boardMEMF [/system resource get free-memory];\r\
    \n:local boardMEMT [/system resource get total-memory];\r\
    \n:local boardUptime [/system resource get uptime];\r\
    \n:local boardName [/system resource get board-name];\r\
    \n:local boardArch [/system resource get architecture-name];\r\
    \n\r\
    \n#Clean\r\
    \n:local boardCPU [:pick \$boardCPU 0 [:find \$boardCPU \"%\"]]\r\
    \n\r\
    \n#Send\r\
    \n:local result [tool fetch url=\"\$hivehost/ping.php\?id=\$serialNumber&f\
    w=\$boardFirmware&cpu=\$boardCPU&mem=\$boardMEMF,\$boardMEMT&uptime=\$boar\
    dUptime&hw=\$boardName&arch=\$boardArch\" output=user as-value];\r\
    \n\r\
    \n  :if (\$result->\"status\" = \"finished\") do={\r\
    \n       :log info \"PING: OK\";\r\
    \n      } else={\r\
    \n       :log warn \"PING FAILED\";\r\
    \n  }\r\
    \n\r\
    \n}"
add dont-require-permissions=yes name=mtprobe-ping-bwtest owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#\
    Mikrotik Probe Latency and Bandwidth Testing\r\
    \n#Version 0.1a\r\
    \n\r\
    \n{\r\
    \n:global hivehost;\r\
    \n:global arrayHost [:toarray \"\"];\r\
    \n:global counter 0;\r\
    \n:local serialNumber [/system routerboard get serial-number];\r\
    \n\r\
    \n:foreach value in [/ip firewall address-list find where list=PROBE and d\
    ynamic=yes] do={\r\
    \n:local probe [/ip firewall address-list get \$value address];\r\
    \n:set (\$arrayHost->\$counter) \$probe;\r\
    \n:set \$counter (\$counter + 1);\r\
    \n}\r\
    \n\r\
    \n:foreach value in [/ip firewall address-list find where list=STATIC and \
    dynamic=no] do={\r\
    \n:local static [/ip firewall address-list get \$value address];\r\
    \n:set (\$arrayHost->\$counter) \$static;\r\
    \n:set \$counter (\$counter + 1);\r\
    \n}\r\
    \n\r\
    \n#Peform loop of hosts to test\r\
    \n:foreach host in=\$arrayHost do={\r\
    \n\r\
    \n:local pingminavgmax 0;\r\
    \n:local jitterminavgmax 0;\r\
    \n:local packetloss 0;\r\
    \n:local tcpdownload 0;\r\
    \n:local tcpupload 0;\r\
    \n:local sysname [/system identity get name]\r\
    \n\r\
    \n#Run Speed-Test\r\
    \n:tool speed-test \$host duration=30 do={\r\
    \n:set pingminavgmax \$\"ping-min-avg-max\";\r\
    \n:set jitterminavgmax \$\"jitter-min-avg-max\";\r\
    \n:set tcpdownload \$\"tcp-download\";\r\
    \n:set tcpupload \$\"tcp-upload\";\r\
    \n:set packetloss \$\"loss\";\r\
    \n}\r\
    \n\r\
    \n\r\
    \n:local packetloss [:pick \$packetloss 0 [:find \$packetloss \" \"]]\r\
    \n:local tcpdownload [:pick \$tcpdownload 0 [:find \$tcpdownload \" \"]]\r\
    \n:local tcpupload [:pick \$tcpupload 0 [:find \$tcpupload \" \"]]\r\
    \n\r\
    \n#Clean-Up Function\r\
    \n:local cleanup do={\r\
    \n:local avg 0;\r\
    \n:if ([:find \$1 \"/\" -1] > 0) do={\r\
    \n :for i from=0 to=([:len \$1] -1) step=1 do={\r\
    \n  :local actualchar value=[:pick \$1 \$i];\r\
    \n  :if (\$actualchar = \"/\") do={ :set actualchar value=\",\" };\r\
    \n  :if (\$actualchar = \" \") do={ :set actualchar value=\"\" };\r\
    \n  :set avg value=(\$avg.\$actualchar);\r\
    \n }\r\
    \n  :return \$avg;\r\
    \n }\r\
    \n}\r\
    \n\r\
    \n:local pingavg [\$cleanup \$pingminavgmax];\r\
    \n:local pingArray [toarray \$pingavg];\r\
    \n:local pingavgout [:pick \$pingArray 1];\r\
    \n\r\
    \n:local jittavg [\$cleanup \$jitterminavgmax];\r\
    \n:local jittArray [toarray \$jittavg];\r\
    \n:local jittavgout [:pick \$jittArray 1];\r\
    \n\r\
    \n#Build file log line format\r\
    \n:log info \"\$sysname \$host - [\$pingavgout/\$jittavgout] [\$packetloss\
    ] [\$tcpdownload/\$tcpupload]\";\r\
    \n\r\
    \n#Send\r\
    \n:local result [tool fetch url=\"\$hivehost/results.php\?id=\$serialNumbe\
    r&host=\$host&ping=\$pingavgout&jitter=\$jittavgout&tcpd=\$tcpdownload&tcp\
    u=\$tcpupload\" output=user as-value];\r\
    \n\r\
    \n  :if (\$result->\"status\" = \"finished\") do={\r\
    \n       :log info \"RESULTS: OK\";\r\
    \n      } else={\r\
    \n       :log warn \"RESULTS: FAILED\";\r\
    \n  }\r\
    \n}\r\
    \n\r\
    \n#cleanup globals\r\
    \n:set counter;\r\
    \n:set arrayHost;\r\
    \n}\r\
    \n\r\
    \n"
/tool netwatch
add down-script="/system leds set type=off [find leds=user-led]" host=1.1.1.1 \
    up-script="/system leds set type=on [find leds=user-led]"

