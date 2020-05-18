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
:local result [tool fetch url="http://$hivehost/ping.php?id=$serialNumber&fw=$boardFirmware&cpu=$boardCPU&mem=$boardMEMF,$boardMEMT&uptime=$boardUptime&hw=$boardName&arch=$boardArch&ping=$avgrtt" output=user as-value];

  :if ($result->"status" = "finished") do={
       :log info "PING: OK";
      } else={
       :log warn "PING FAILED";
  }

}
