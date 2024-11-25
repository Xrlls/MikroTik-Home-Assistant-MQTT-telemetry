:local discoverypath "homeassistant/"

:foreach ups in=[/system/ups/find] do={
    :local state [/system/ups/monitor $ups once as-value]

    :local stateout
    if ($state->"on-line") do={
        :set ($stateout->"on_line") "ON"
    } else={
        :set ($stateout->"on_line") "OFF"
    }
    :set ($stateout->"battery_charge") ($state->"battery-charge")
    :set ($stateout->"load") ($state->"load")

    #--- Convert time to fractional minutes ---
    :local ci [:find [:tostr ($state->"runtime-left")] ":" -1]
    :local ci2 [:find ($state->"runtime-left") ":" $ci]
    :set ($stateout->"runtime_left") ([:pick ($state->"runtime-left") -1 ($ci)] * 60 ); #Convert hours to minutes
    :set ($stateout->"runtime_left") ((($stateout->"runtime_left") + [:pick ($state->"runtime-left") ($ci+1) $ci2]) * 60 )
    :set ($stateout->"runtime_left") ( ($stateout->"runtime_left") + [:pick ($state->"runtime-left") ($ci2+1) [:len ($state->"runtime-left")]])
    #------------------------------------------

    :set ($stateout->"battery_voltage") ($state->"battery-voltage")
    :set ($stateout->"hid_self_test") ($state->"hid-self-test")
    :set ($stateout->"line_voltage") ($state->"line-voltage")

    /iot/mqtt/publish broker="Home Assistant" topic=($discoverypath."sensor/".[/system/ups/get $ups serial]."/state") message=[:serialize $stateout to=json]
}