#Check PROBE Address list for up hosts

{
#Run through all the hosts tests need to be performed against UP hosts first.
:foreach value in [/ip firewall address-list find where list=PROBE and dynamic=yes] do={
:local host [/ip firewall address-list get $value address];
:local hostcomment [/ip firewall address-list get $value comment];

:local avgrtt 0;
:local sending 0;
:local rec 0;

  :tool flood-ping $host size=50 count=5  timeout=1s do={
      :if ($sent=5) do= {
          :set avgrtt ($"avg-rtt")
          :set sending ($"sent")
          :set rec ($"received")
      }
  }

 :if ($rec != 0 ) do={
  #:local test [ip firewall address-list set comment="UP" [find list=PROBE address=$hostcomment]];
  :log info "[$host] $hostcomment OK $sending/$rec"; 
  } else= { 
  :local test [ip firewall address-list set disabled=yes [find list=PROBE address=$hostcomment]];
  :log warn "[$host] $hostcomment DOWN - DISABLED - $sending/$rec"; 
  }
 }

#Run through all the hosts tests need to be performed against DOWN hosts second.
:foreach value in [/ip firewall address-list find where list=PROBE and disabled=yes] do={
:local host [/ip firewall address-list get $value address];

:local avgrtt 0;
:local sending 0;
:local rec 0;

:local hostip [:resolve $host;];

  :tool flood-ping $hostip size=50 count=5  timeout=1s do={
      :if ($sent=5) do= {
          :set avgrtt ($"avg-rtt")
          :set sending ($"sent")
          :set rec ($"received")
      }
  }

 :if ($rec != 0 ) do={
  :local test [ip firewall address-list set disabled=no [find list=PROBE address=$host]];
  :log info "[$host] UP - ENABLED $sending/$rec"; 
  } else= { 
  #:local test [ip firewall address-list set disabled=yes [find list=PROBE address=$hostcomment]];
  :log warn "[$host] STILL DOWN - $sending/$rec"; 
  }
 }

}

