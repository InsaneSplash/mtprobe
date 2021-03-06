{
:global hivehost;
:local avgrtt 0;
:local sending 0;
:local rec 0;

#Collect
:local serialNumber [/system routerboard get serial-number];
:local boardFirmware [/system routerboard get current-firmware];
:local boardCPU [/system resource get cpu-load];
:local boardMEMF [/system resource get free-memory];
:local boardMEMT [/system resource get total-memory];
:local boardUptime [/system resource get uptime];
:local boardName [/system resource get board-name];
:local boardArch [/system resource get architecture-name];

#Clean
:local boardCPU [:pick $boardCPU 0 [:find $boardCPU "%"]]

  :tool flood-ping $hivehost size=50 count=10  timeout=1 do={
      :if ($sent=10) do= {
          :set avgrtt ($"avg-rtt")
          :set sending ($"sent")
          :set rec ($"received")
      }
  }

#Send

:local result [tool fetch http-method=post http-header-field="Content-Type: application/x-www-form-urlencoded" url="http://$hivehost:8086/write\?db=mtprobe" http-data="stats,serial=$serialNumber cpu=$boardCPU\n stats,serial=$serialNumber memf=$boardMEMF\n stats,serial=$serialNumber memt=$boardMEMT\n stats,serial=$serialNumber ping=$avgrtt" output=user as-value];

:put ($result->"data");

  :if ($result->"status" = "finished") do={
       :local statusCode ($result->"data");
       :log info "PING DATA OK";     
      } else={
       :log warn "PING DATA FAILED";
  }

}
