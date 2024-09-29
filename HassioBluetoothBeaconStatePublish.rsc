:global HassioKnownBT

#----------------------
# Publish tracker state
#----------------------
:local PublishState do={       
    :global HassioKnownBT
    :local PublishEntities [:parse [/system/script/get HassioLib_BluetoothBeaconEntityPublish source ]]
    :local TimeStamp ([:totime $2]-([/system/clock/get gmt-offset]."s")) ;#Convert timmestamp to GMT. This will be toxic around daylight savings
    #Prepare common data 
    :local dtopic [([:pick $1 -1 2].[:pick $1 3 5].\
                    [:pick $1 6 8].[:pick $1 9 11].\
                    [:pick $1 12 14].[:pick $1 15 17])]
    :set dtopic [:convert $dtopic transform=lc]
    :local out
    :local site "home"
    #Check if away message should be published.
    :if ([:len $4]=0) do={;#No data, publish away
        :log info "HassioBtrack: Publishing away message"
        :set ($out->"last_seen") ($HassioKnownBT->$1->"tsi")
        :set $site "not_home"
        :set ($HassioKnownBT->$1)
        /iot/mqtt/publish broker="Home Assistant" topic="homeassistant/sensor/$dtopic/state"\
            message=[:serialize $out to=json]
        /iot/mqtt/publish broker="Home Assistant" topic="homeassistant/device_tracker/$dtopic/state" message=$site
        /log info "BTRACK: state sent"
    } else={;#Data included, publish normal
        #Check if device is known
        :if ([:typeof ($HassioKnownBT->$1->"ts")]="nothing") do={; #Device is unknown
            :set ($HassioKnownBT->$1->"ts") 0s;
            :local temp true
            if ([:pick $4 28 32]="0080") do={:set temp false; log info "HassioBTRACK: Found beacon without thermometer"}
            $PublishEntities $1 $temp
            :log info  "BTRACK: unknown device, reset TS";#set timestamp to start of epoch if nonexistent
        }
        :if ($TimeStamp>($HassioKnownBT->$1->"ts")) do={;# Message is newer than last published
            :set ($HassioKnownBT->$1->"state") [ :pick $4 40 42]
            :set ($HassioKnownBT->$1->"ts") $TimeStamp
      
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
                    :set $site "hassio_gps_derive"
                }
            } on-error={:log info "HassioBTRACK: GNSS unavailable, not publishing coordinates"}
        /iot/mqtt/publish broker="Home Assistant" topic="homeassistant/sensor/$dtopic/state"\
            message=[:serialize $out to=json]
        /iot/mqtt/publish broker="Home Assistant" topic="homeassistant/device_tracker/$dtopic/state" message=$site
        /log info "HassioBTRACK: state sent"
        }
    };# else={log info "BTRACK: Discarded due to timestamp being older or identical"}    
}
#----------------------
#Process all messages in case of captured events
#----------------------
/iot/bluetooth/scanners/advertisements
:local BeaconData [print proplist=address,rssi,time,data as-value where data~"^..ff4f0901"]
clear; #What happens with frames received between print and clear

:foreach beacon in=$BeaconData do={
    :local State [ :pick ($beacon->"data") 40 42]
    :if ($State!=($HassioKnownBT->($beacon->"address")->"state")) do={ ; #Check if state has changed
        :log info "BTRACK: changed state, move to transmit..."
        $PublishState ($beacon->"address") ($beacon->"time") ($beacon->"rssi") ($beacon->"data")
    } else={:log info "BTRACK: Discarded due to no change in state"}
}

#----------------------
#Process latest message
#----------------------
/iot/bluetooth/peripheral-devices
:foreach beacon in=[find beacon-types="mikrotik"] do={
    :local state [get $beacon]
    :if (($state->"last-data")~"^..FF4F0901") do={
         $PublishState ($state->"address") ($state->"last-seen") ($state->"rssi") ($state->"last-data")
    }
}

#----------------------
#Publish away location for all devices not seen lately
#----------------------
:foreach beacon,data in=$HassioKnownBT do={
    :if (($data->"ts")<([:timestamp]-1m)) do={
        :log info "BTRACK: Device $beacon not seen within timeout. Publish \"away\" and remove from known list."
        #Publish away message
        $PublishState $beacon
    } else={
        :log info "BTRACK: Device seen within timeout, moving on..."
    }

}

