if ([len [system/package/find name="iot"]]=0) do={ ; # If IOT packages is  not installed
    log/error message="HassioMQTT: IOT package not installed."
} else={
    if ([len [iot/mqtt/brokers/find name="Home Assistant"]]=0) do={ ;# If Home assistant broker does not exist
        log/error message="HassioMQTT: Broker does not exist."
    } else={
        while (![/iot/mqtt/brokers/get [/iot/mqtt/brokers/find name="Home Assistant"] connected ]) do={ ;# If Home assistant broker is not connected
            log/info message="HassioMQTT: Broker not connected reattempting connection..."
            delay 1m; # Wait and attempt reconnect
            iot/mqtt/connect broker="Home Assistant"
        }

        local discoverypath "homeassistant/"
        local domainpath "sensor"

        #-------------------------------------------------------
        #Build device string
        #-------------------------------------------------------
        local dev [[parse [system/script/get "HassioLib_DeviceString" source]]]
        local buildconfig do= {
            local SearchReplace [parse [system/script/get "HassioLib_SearchReplace" source]]

            #build config for Hassio
           local entity
            set $entity ($entity,$dev)
            :foreach dname,iname in=$name do={
                :local jsonname ("x".[$SearchReplace input=$dname search="-" replace="_"])
                :set $dname ($dname.$NamePostfix)
                :set ($entity->"cmps"->$dname) {
                    "p"= $domainpath
                    "name"=("$iname"." PoE")
                    "~"=("$discoverypath$domainpath/".($entity->"dev"->"ids")."/state$NamePostfix")
                    "stat_t"="~"
                    "avty_t"="~"
                    "uniq_id"=(($entity->"dev"->"ids")."_$dname")
#                    "obj_id"=($entity->"cmps"->$dname->"uniq_id")
                    "sug_dsp_prc"=1
                    "unit_of_meas"=$unit
                    "dev_cla"="power"
                    "stat_cla"="measurement"
                    "val_tpl"="\
                    {%if value_json.$jsonname is defined%}\
                        {{value_json.$jsonname/10}}\
                    {%else%}\
                        {{0}\
                    }{%endif%}"
                    "avty_tpl"="\
                    {%if value_json.$jsonname is defined%}\
                        {{'online'}}\
                    {%else%}\
                        {{'offline'}}\
                    {%endif%}"
                    "exp_aft"=70}
                #/iot/mqtt/publish broker="Home Assistant" message=[:serialize $entity to=json]\
                #    topic=("$discoverypath$domainpath".($entity->"dev"->"ids")."/$name$NamePostfix/config") retain=yes
            :set ($entity->"cmps"->$dname->"obj_id") ($entity->"cmps"->$dname->"uniq_id")
            }
            :return $entity;#[:serialize to=json $entity]
        }
        :local all
        foreach sensor in=[/interface/ethernet/poe/find] do={
            :local iname [/interface/ethernet/poe/get $sensor name];#Friendly name
            :local dname [/interface/ethernet get [find name=$iname] default-name]
            :set ($all->dname) $iname
#            $buildconfig name=($dname) iname=$iname unit=W NamePostfix="_poe" discoverypath=$discoverypath domainpath=$domainpath dev=$dev
        }
        :return [$buildconfig name=$all unit=W NamePostfix="_poe" discoverypath=$discoverypath domainpath=$domainpath dev=$dev]
    }
}