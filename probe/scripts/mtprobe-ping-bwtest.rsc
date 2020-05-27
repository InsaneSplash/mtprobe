#Mikrotik Probe Latency and Bandwidth Testing
#Version 0.1a

{
:global hivehost;
:global arrayHost [:toarray ""];
:global counter 0;
:global pingavgout 0;
:global jittavgout 0;

:local serialNumber [/system routerboard get serial-number];

:foreach value in [/ip firewall address-list find where list=PROBE and dynamic=yes] do={
:local probe [/ip firewall address-list get $value address];
:set ($arrayHost->$counter) $probe;
:set $counter ($counter + 1);
}

:foreach value in [/ip firewall address-list find where list=STATIC and dynamic=no] do={
:local static [/ip firewall address-list get $value address];
:set ($arrayHost->$counter) $static;
:set $counter ($counter + 1);
}

#Peform loop of hosts to test
:foreach host in=$arrayHost do={

:local pingminavgmax 0;
:local jitterminavgmax 0;
:local packetloss 0;
:local tcpdownload 0;
:local tcpupload 0;
:local sysname [/system identity get name]

#Run Speed-Test
:tool speed-test $host duration=30 do={
:set pingminavgmax $"ping-min-avg-max";
:set jitterminavgmax $"jitter-min-avg-max";
:set tcpdownload $"tcp-download";
:set tcpupload $"tcp-upload";
:set packetloss $"loss";
}


:local packetloss [:pick $packetloss 0 [:find $packetloss "%"]]
:local tcpdownload [:pick $tcpdownload 0 [:find $tcpdownload "M"]]
:local tcpupload [:pick $tcpupload 0 [:find $tcpupload "M"]]

#Clean-Up Function
:local cleanup do={

:if ([:find $1 "/" -1] > 0) do={
:local avg 0;
 :for i from=0 to=([:len $1] -1) step=1 do={
  :local actualchar value=[:pick $1 $i];
  :if ($actualchar = "/") do={ :set actualchar value="," };
  :if ($actualchar = " ") do={ :set actualchar value="" };
  :if (($actualchar = "m") || ($actualchar = "s") || ($actualchar = "u")) do={ :set actualchar value="" };
  :set avg value=($avg.$actualchar);
 }
  :return $avg;
 }
}
#If ping/latency is in nano seconds we have a problem

:if (pingminavgmax ~ "us") do={
:local pingavg [$cleanup $pingminavgmax];
:local pingArray [toarray $pingavg];
:local pingavgoutPre [:pick $pingArray 1];
:set pingavgout value=("0.".$pingavgoutPre);

} else {
:local pingavg [$cleanup $pingminavgmax];
:local pingArray [toarray $pingavg];
:set pingavgout [:pick $pingArray 1];
}


:if (jitterminavgmax ~ "us") do={
:local jittavg [$cleanup $jitterminavgmax];
:local jittArray [toarray $jittavg];
:local jittavgoutPre [:pick $jittArray 1];
:set jittavgout value=("0.".$jittavgoutPre);

} else {
:local jittavg [$cleanup $jitterminavgmax];
:local jittArray [toarray $jittavg];
:set jittavgout [:pick $jittArray 1];
}

#Build file log line format
:log info "$sysname $host - [$pingavgout/$jittavgout] [$packetloss] [$tcpdownload/$tcpupload]";

#Send

:local result [tool fetch http-method=post http-header-field="Content-Type: application/x-www-form-urlencoded" url="http://$hivehost:8086/write\?db=mtprobe" http-data="\
bwtest,serial=$serialNumber,testhost=$host ploss=$packetloss\n\
bwtest,serial=$serialNumber,testhost=$host tcpd=$tcpdownload\n\
bwtest,serial=$serialNumber,testhost=$host tcpu=$tcpupload\n\
bwtest,serial=$serialNumber,testhost=$host pingavg=$pingavgout\n\
bwtest,serial=$serialNumber,testhost=$host jitteravg=$jittavgout\n\
" output=user as-value];

  :if ($result->"status" = "finished") do={
       :log info "RESULTS: OK";
      } else={
       :log warn "RESULTS: FAILED";
  }
}

#cleanup globals
:set counter;
:set arrayHost;
:set pingavgout;
:set jittavgout;
}

