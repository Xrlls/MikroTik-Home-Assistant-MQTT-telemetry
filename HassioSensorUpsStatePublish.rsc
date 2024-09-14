:local discoverypath "homeassistant/"

#--- Function to convert integer to dec ---
:local adec do={
    :if ([len $1]<=$2) do={; #add leading zeros for numbers with few digits
        :for i from=[:len $1] to=$2 do={:set $1 "0$1"}
        }
    :return ([:pick $1  -1 ([:len $1]-$2)].".".\
             [:pick $1 ([:len $1]-$2) [:len $1] ])
    }
#------------------------------------------

:foreach ups in=[/system/ups/find] do={
:local state [/system/ups/monitor $ups once as-value]

:local stateout
:if ($state->"on-line") do={:set ($stateout->"on_line") "ON"} else={:set ($stateout->"on_line") "OFF"}
:set ($stateout->"battery_charge") ($state->"battery-charge")
:set ($stateout->"load") ($state->"load")

#--- Convert time to fractional minutes ---
:local ci [:find [:tostr ($state->"runtime-left")] ":" -1]
:set ($stateout->"runtime_left") ([:pick ($state->"runtime-left") -1 ($ci)] * 60 ); #Convert hours to minutes
:local ci2 [:find ($state->"runtime-left") ":" $ci]
:set ($stateout->"runtime_left") ((($stateout->"runtime_left") + [:pick ($state->"runtime-left") ($ci+1) $ci2]) * 60 )
:set ($stateout->"runtime_left") ( ($stateout->"runtime_left") + [:pick ($state->"runtime-left") ($ci2+1) [:len ($state->"runtime-left")]])
:set ($stateout->"runtime_left") [$adec (($stateout->"runtime_left")*1667) 5]; #Convert seconds to fractional minutes
#------------------------------------------

:set ($stateout->"battery_voltage") [$adec ($state->"battery-voltage") 2]
:set ($stateout->"hid_self_test") ($state->"hid-self-test")
:set ($stateout->"line_voltage") [$adec ($state->"line-voltage") 2]

/iot/mqtt/publish broker="Home Assistant" topic=($discoverypath."sensor/".[/system/ups/get $ups serial]."/state") message=[:serialize $stateout to=json]
}