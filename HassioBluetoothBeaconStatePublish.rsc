:global HassioKnownBT
:global HassioBtTimeStamp
#----------------------
# Publish tracker state
#----------------------
:local PublishState do={       
    :global HassioKnownBT    
    #Prepare common data 
    :local dtopic [([:pick $1 -1 2].[:pick $1 3 5].\
                    [:pick $1 6 8].[:pick $1 9 11].\
                    [:pick $1 12 14].[:pick $1 15 17])]
    :set dtopic [:convert $dtopic transform=lc]
    :local retain false
    :local out
    :set ($out->"site") "home"
    #Check if away message should be published.
    :if ([:len $4]=0) do={;#No data, publish away
        :log debug "HassioBtrack: $1 Publishing away message"
        :set ($out->"last_seen") ($HassioKnownBT->$1->"tsi")
        :set ($out->"site") "not_home"
        :set ($HassioKnownBT->$1)
        :set $retain true
    } else={;#Data included, publish normal
        #Check if device is known
        :if ([:typeof ($HassioKnownBT->$1->"ts")]="nothing") do={; #Device is unknown
            :set ($HassioKnownBT->$1->"ts") 0;
            :log debug "HassioBtrack: $1 unknown device, reset TS";#set timestamp to start of epoch if nonexistent
            :local temp true
            :if ([:pick $4 28 32]="0080") do={
                :set temp false; 
                log debug "HassioBtrack: $1 Found beacon without thermometer (TG-BT5-IN)"
            }
            :local PublishEntities [:parse [/system/script/get HassioLib_BluetoothBeaconEntityPublish source ]]
            $PublishEntities $1 $temp
        }
        :set ($HassioKnownBT->$1->"state") [ :pick $4 40 42]
        :set ($HassioKnownBT->$1->"ts") $5
        :set ($out->"last_seen") ($2.[/system/clock/get gmt-offset as-string])
        :set ($HassioKnownBT->$1->"tsi") ($out->"last_seen")
        :set ($out->"rssi") $3
        :set ($out->"data") $4
        #Set GNSS coordinates
        do {
            :local pos [[:parse "/system/gps monitor once as-value"]]
            :if ($pos->"valid") do={
                :set ($out->"latitude") ($pos->"latitude")
                :set ($out->"longitude") ($pos->"longitude")
                :set ($out->"site") "hassio_gps_derive"
            }
        } on-error={:log debug "HassioBtrack: GNSS unavailable, not publishing coordinates"}
    }
    /iot/mqtt/publish broker="Home Assistant" topic="homeassistant/sensor/$dtopic/state"\
        message=[:serialize $out to=json] retain=$retain
    /log debug "HassioBtrack: $1 state sent"
}

#----------------------
#Initialize TimeStamp on first run
#----------------------
:if ([:typeof $HassioBtTimeStamp]="nothing") do={:set $HassioBtTimeStamp 0}

#----------------------
#Process all messages in case of captured events
#----------------------
:log debug "HassioBtrack: Started"
/iot/bluetooth/scanners/advertisements
:local FrameCache

:foreach index in=[find epoch>$HassioBtTimeStamp and data~"^..ff4f0901"] do={
    :local beacon [get $index]
    :set $HassioBtTimeStamp ($beacon->"epoch")
    :local State [ :pick ($beacon->"data") 40 42]
    :if ($State!=($HassioKnownBT->($beacon->"address")->"state")) do={ ; #Check if state has changed
        :log debug ("HassioBtrack: ".($beacon->"address")." changed state, move to transmit...")
        $PublishState ($beacon->"address") ($beacon->"time") ($beacon->"rssi") ($beacon->"data") ($beacon->"epoch")
        :set ($FrameCache->($beacon->"address"))
    } else={
        :log debug ("HassioBtrack: ".($beacon->"address")." Cached due to no change in state")
        :set ($FrameCache->($beacon->"address")) $beacon
    }
}
#----------------------
#Process latest message
#----------------------
:foreach beacon in=$FrameCache do={
    :log debug ("HassioBtrack: ".($beacon->"address")." Cached frame, move to transmit...")
    $PublishState ($beacon->"address") ($beacon->"time") ($beacon->"rssi") ($beacon->"data") ($beacon->"epoch")
    :set ($FrameCache->($beacon->"address"))
}

#----------------------
#Publish away location for all devices not seen lately
#----------------------
:foreach beacon,data in=$HassioKnownBT do={
    :if (($data->"ts")<([:tonum ([:timestamp])]-60)*1000) do={
        :log debug "HassioBtrack: $beacon not seen within timeout. Publish \"away\" and remove from known list."
        #Publish away message
        $PublishState $beacon
    } else={
        :log debug "HassioBtrack: $beacon seen within timeout, moving on..."
    }

}
