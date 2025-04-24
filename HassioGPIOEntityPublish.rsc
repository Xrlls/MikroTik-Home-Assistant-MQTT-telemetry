:local discoverypath "homeassistant/"

#-------------------------------------------------------
#Build device string
#-------------------------------------------------------
:local dev [[:parse [system/script/get "HassioLib_DeviceString" source]]]
:local buildconfig do={
    :local SearchReplace [:parse [system/script/get "HassioLib_SearchReplace" source]]
    :local NamePostfix "_GPIO"

    #build config for Hassio
    :local entity
    :set $entity ($entity,$dev)
    :foreach eName,domainpath in=$name do={
        :local jsonname ("x".[$SearchReplace input=$eName search="-" replace="_"])
        :local dName ($eName.$NamePostfix)
        :set ($entity->"cmps"->$dName->"p") $domainpath
        :set ($entity->"cmps"->$dName->"name") $eName
        :set ($entity->"cmps"->$dName->"~") ($discoverypath."sensor/".($entity->"dev"->"ids")."/")
        :set ($entity->"cmps"->$dName->"stat_t") "~state$NamePostfix"
        :set ($entity->"cmps"->$dName->"avty_t") "~state$NamePostfix"
        :set ($entity->"cmps"->$dName->"avty_tpl")\
            "{%if value_json.$jsonname is defined%}\
                {{'online'}}\
            {%else%}\
                {{'offline'}}\
            {%endif%}"
        :set ($entity->"cmps"->$dName->"uniq_id") (($entity->"dev"->"ids")."_$dName")
        :set ($entity->"cmps"->$dName->"obj_id") ($entity->"cmps"->$dName->"uniq_id")

        :if ($domainpath="sensor") do={
            :set ($entity->"cmps"->$dName->"sug_dsp_prc") 3
            :set ($entity->"cmps"->$dName->"unit_of_meas") "V"
            :set ($entity->"cmps"->$dName->"dev_cla") "voltage"
            :set ($entity->"cmps"->$dName->"stat_cla") "measurement"
            :set ($entity->"cmps"->$dName->"val_tpl")\
                "{%if value_json.$jsonname is defined%}\
                    {{value_json.$jsonname/1000}}\
                {%endif%}"
            :set ($entity->"cmps"->$dName->"exp_aft") 70
        }
        :if ($domainpath="binary_sensor") do={
            :set ($entity->"cmps"->$dName->"val_tpl")\
                "{%if value_json.$jsonname is defined%}\
                    {%if value_json.$jsonname%}\
                        {{'ON'}}\
                    {%else%}\
                        {{'OFF'}}\
                    {%endif%}\
                {%endif%}"
        }
        :if ($domainpath="switch") do={
            :set ($entity->"cmps"->$dName->"val_tpl")\
                "{%if value_json.$jsonname is defined%}\
                    {%if value_json.$jsonname%}\
                        {{'ON'}}\
                    {%else%}\
                        {{'OFF'}}\
                    {%endif%}\
                {%endif%}"
            :set ($entity->"cmps"->$dName->"cmd_t") ($discoverypath.$domainpath."/".($entity->"dev"->"ids")."/command_$jsonname$NamePostfix")
        }
    }
#    /iot/mqtt/publish broker="Home Assistant" message=[:serialize $entity to=json]\
#        topic=("$discoverypath$domainpath/".($entity->"dev"->"ids")."/$name$NamePostfix/config") retain=yes        
#    :return $entity;
    :return [:serialize to=json $entity]
}

:local all

/iot/gpio/analog
:foreach input in=[find] do={
#    $buildconfig dev=$dev name=[get $input name] domainpath="sensor" discoverypath=$discoverypath
    :set ($all->[get $input name]) "sensor"
}

/iot/gpio/digital
:foreach input in=[find where direction="input"] do={
    :if ([get $input input]!="(unknown)") do={; #Workaround as Knot is listing pin3 as both analog and digital, while it is only analog. 
#        $buildconfig dev=$dev name=[get $input name] domainpath="binary_sensor" discoverypath=$discoverypath
        :set ($all->[get $input name]) "binary_sensor"
    }
}

:foreach input in=[find where direction="output"] do={
#    $buildconfig dev=$dev name=[get $input name] domainpath="switch" discoverypath=$discoverypath
    :set ($all->[get $input name]) "switch"
}
:return [$buildconfig name=$all discoverypath=$discoverypath dev=$dev]
